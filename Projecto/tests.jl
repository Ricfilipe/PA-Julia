# Tests version 0.0
# Date: May, 14, 2019, 11h52
# Contact catarina.belem[at]tecnico.ulisboa.pt for any question regarding the tests

# This file should be placed in the same directory as the JOS.jl. Alternatively,
# you can change the path of the file in include("relativepath/to/srcfolder/JOS.jl").
include("JOS.jl")

import Base.@assert
# -------------------------------------------------------------------------
#                           Auxiliar Test Functions
# -------------------------------------------------------------------------
ntests = 0
nfailed = 0
tests_failed = []
macro assert(expr)
    quote
        $(esc(:ntests)) += 1
        if !$expr
            $(esc(:nfailed)) += 1
            push!($(esc(:tests_failed)), $(esc(:ntests)))
            "Failed Test $(ntests)"
        else
            "Passed Test $(ntests)"
        end
    end
end

slot_error(slot_name, type_error) = "Slot $(slot_name) is $(type_error)"
method_error() = "No applicable method"

test_error(f, error) =
    try f()
        false
    catch ex
        sprint(showerror, ex) == error
    end

# -------------------------------------------------------------------------
#                               Tests
# -------------------------------------------------------------------------
# Every @assert is consider to be a single instance of a test.
# This script is intended to be run sequentially. Due to the use of global
# variables to count the failed tests and to identify them.
# Nevertheless, every time a test fails an output message will be displayed
# stating that you've failed a test with a specific number. If you try to run
# that test multiple times, you will see the test id changing. Given the
# provided implementation this is the expected behavior.
# -------------------------------------------------------------------------

Person = make_class(:Person, [], [:name, :age]);
Researcher = make_class(:Researcher, [], [:group]);
@defclass(Student, [Person], course);
@defclass(Sportsman, [], activity, schedule);

@defclass(IstStudent, [Student, Sportsman], []);
@defclass(PhdStudent, [IstStudent, Researcher], []);

# ------------------------------------------------------------------------------

s = make_instance(Student, :name => "Paul", :age => 21, :course => "Informatics");
@assert get_slot(s, :course) == "Informatics"                                   # Test 1
@assert s.age == 21                                                             # Test 2

# ------------------------------------------------------------------------------

m1 = make_instance(IstStudent, :name => "Maria", :course => "IA", :activity => "Tennis");
@assert m1.name == "Maria"                                                      # Test 3
@assert m1.activity == "Tennis"                                                 # Test 4
@assert test_error(() -> m1.schedule, slot_error("schedule", "unbound"))        # Test 5
@assert test_error(() -> m1.missingslot, slot_error("missingslot", "missing"))  # Test 6

# ------------------------------------------------------------------------------

m2 = make_instance(IstStudent, :name => "Maria", :course => "IA", :activity => "Tennis");
@assert test_error(() -> m2.schedule, slot_error("schedule", "unbound"))        # Test 7
set_slot!(m2, :schedule, "Mondays, Thursdays: 9am-10am.");
@assert m2.schedule == "Mondays, Thursdays: 9am-10am."                          # Test 8
m2.name = "Maria JoÃ£o";
@assert m2.name == "Maria JoÃ£o"                                                 # Test 9
@assert test_error(() -> make_instance(IstStudent, :nme => "Maria"),
                    slot_error("nme", "missing"))                               # Test 10

# ------------------------------------------------------------------------------
@defgeneric what_do_you_do(p);
@defmethod what_do_you_do(p::Person) = "I, $(p.name), just breathe!";
@defmethod what_do_you_do(p::Sportsman) = "I run!";
@defmethod what_do_you_do(p::Researcher) = "I do experiments and research at $(p.group)! But not in rats!";

@assert what_do_you_do(make_instance(Person,
                        :name => "MÃ¡rio")) == "I, MÃ¡rio, just breathe!"         # Test 11
@assert what_do_you_do(make_instance(IstStudent,
                        :name => "InÃªs")) == "I, InÃªs, just breathe!"           # Test 12
@assert what_do_you_do(make_instance(Researcher,
                        :group => "ADA")) == "I do experiments and research at ADA! But not in rats!" # Test 13
@assert what_do_you_do(make_instance(PhdStudent,
                        :group => "ADA",
                        :name => "Renata",
                        :course => "Advanced Programming")) == "I, Renata, just breathe!" # Test 14

# ------------------------------------------------------------------------------

@defmethod what_do_you_do(p::Student) = "I study $(p.course)! This is incredibly complex!";
@assert what_do_you_do(make_instance(IstStudent,
                        :name => "InÃªs",
                        :course => "Advanced Programming")) == "I study Advanced Programming! This is incredibly complex!" # Test 15
@assert what_do_you_do(make_instance(PhdStudent,
                        :group => "ADA",
                        :name => "Renata",
                        :course => "Advanced Programming")) == "I study Advanced Programming! This is incredibly complex!" # Test 16

# ------------------------------------------------------------------------------

@defgeneric work_on_project(x, y);
@defmethod work_on_project(x::Person, y::Sportsman) = "$(x.name) is watching a young adult playing $(y.activity) instead of working on the project.";
@defmethod work_on_project(x::Person, y::IstStudent) = "$(x.name) is watching the IST Student, $(y.name), studying and doing the project of the course $(y.course)...";
@defmethod work_on_project(x::IstStudent, y::Person) = "The IST Student $(x.name) is studying and doing the project and $(y.name) is watching...";
@defmethod work_on_project(x::IstStudent, y::IstStudent) = "Both $(x.name) and $(y.name) are working on the project!";

p1 = make_instance(Person, :name => "Anna");
s1 = make_instance(Sportsman, :activity => "Synchronized Swimming");
ist1 = make_instance(IstStudent, :name=>"Edmond", :course=>"AI");
ist2 = make_instance(IstStudent, :course=>"Advanced Programming", :name=>"Martia");
@assert work_on_project(p1, s1) == "Anna is watching a young adult playing Synchronized Swimming instead of working on the project."  # Test  17
@assert test_error(() -> work_on_project(s1, p1), method_error())   # Test 18
@assert work_on_project(p1, ist1) == "Anna is watching the IST Student, Edmond, studying and doing the project of the course AI..." # Test 19
@assert work_on_project(ist1, p1) == "The IST Student Edmond is studying and doing the project and Anna is watching..."   # Test 20

@assert work_on_project(ist1, ist2) == "Both Edmond and Martia are working on the project!" # Test 21

# Print total counts of failed tests
println(">> Failed $(nfailed)/$(ntests) tests\n - Failed tests: $(join(tests_failed, ", "))")
