struct Class
   name :: Symbol
   hierarchy
   fields:: Tuple
end # struct

struct Instance
   class::Class
   fields::Dict
end # struct

struct GenericFuntion
   name :: Symbol
   parameters
   num::Int
   specific :: Dict
end # struct

struct SpecificMethod
   parent
   types
   native_function
end # struct

#Tranlator for primitives
const Translator = Dict{Symbol,Any}()
Translator[:Int] = Symbol(Int)
Translator[:Dict] = Symbol(Dict{Any,Any})

function make_class(name,super,fields)
   realParents = tuple(name)
   realFields = tuple(fields...)
   for sp in super
      for pare in getfield(sp,:hierarchy)
         if !(pare in realParents)
            realParents = (realParents...,pare)
         end
      end
      for field in getfield(sp,:fields)
         if !(field in realFields)
            realFields = (realFields...,field)
         end
      end
   end
   return Class(name,realParents,realFields)
end

function Symbol(arg::Class)
   return arg.name
end

function make_instance(class,init...)
   dic = Dict{Symbol,Any}()
   for f in class.fields
      dic[f] = nothing
   end
   inst = Instance(class,dic)
   for p in init
      set_slot!(inst,p.first,p.second)
   end
   return inst
end

function Base.getproperty(obj::Instance, sym::Symbol)
   dic = getfield(obj,:fields)
   if haskey(dic,sym)
      slot = get(dic,sym,nothing)
      if slot === nothing
         error("Slot $sym is unbound")
      end
      return slot
   else
      error("Slot $sym is missing")
   end
end

function Base.setproperty!(obj::Instance, sym::Symbol,x)
   dic = getfield(obj,:fields)
   if haskey(dic,sym)
      return dic[sym] = x
   else
      error("Slot $sym is missing")
   end
end

macro defclass(name,super,fields...)
   sym = Expr(:quote,name)
   realFields=[:($(Symbol(entry))) for entry in fields]
   :($(esc(name)) = make_class($(sym),$super,$realFields))
end

function get_slot(obj::Instance,sym::Symbol)
   return getproperty(obj, sym)
end

function set_slot!(obj::Instance,sym::Symbol,value)
   return setproperty!(obj, sym,value)
end

macro defgeneric(expr)
   let name = expr.args[1],
      sym = Expr(:quote,name)
      parameters = (expr.args[2:end])
      meths = Dict{Tuple,SpecificMethod}()
      :($(esc(name)) = GenericFuntion($(sym),$(parameters),size($parameters,1),$meths) )
   end
end

macro defmethod(expr)
   let name = expr.args[1].args[1],
      parameters = (expr.args[1].args[2:end]),
      body =expr.args[2].args[2],
      param_type = [],
      param_var = []
         for i = 1:size(parameters,1)
            push!((param_type),get(Translator,Symbol((parameters[i].args[2])),Symbol((parameters[i].args[2]))))
            push!((param_var),Symbol((parameters[i].args[1])))
         end
         param_var = tuple(param_var...)
         quote
            if size(($parameters),1) !== $(name).num
               error("Wrong number of args")
            end
         $(name).specific[tuple($(param_type)...)] = SpecificMethod($(name),$(param_type), $(Expr(:tuple,param_var...))-> $(body))
      end
   end
end

function doGenericMethod(method :: GenericFuntion , args...)
   temp = []
   for arg in args

      if typeof(arg) === Instance

         temp = push!(temp,getfield(arg,:class))
      else
         temp = push!(temp,(typeof(arg)))
      end
   end

   metd = lookSpecificMethod(1,method.specific,temp)

   if metd !== missing
      return metd.native_function(args...)
   else
      error("No applicable method")
   end
end

#Function responsible for looking for the best suited specific method
function lookSpecificMethod(i :: Int, dic :: Dict,args)
   arg = Any
   if typeof(args[i])==Class
      for arg in args[i].hierarchy
         if i === size(args,1)
            args[end] = arg
            if haskey(dic,tuple(args...))
               return dic[tuple(args...)]
            end
         else
            args[i] = arg
            temp = lookSpecificMethod(i+1, dic,args)
            if temp !== missing
               return temp
            end
         end
      end
      return missing
   else
      arg = args[i]
      while arg !== Any
         if i === size(args,1)
            args[end] = Symbol(arg)
            if haskey(dic,tuple(args...))
               return dic[tuple(args...)]
            end
         else
            args[i] = Symbol(arg)
            temp = lookSpecificMethod(i+1, dic,args)
            if temp !== missing
               return temp
            end
         end
         arg = arg.super
      end
   end

   if arg === Any
      if i === size(args,1)
         args[end] = Symbol(arg)
         if haskey(dic,tuple(args...))
            return dic[tuple(args...)]
         end
      else
         args[i] = Symbol(arg)
         temp = lookSpecificMethod(i+1, dic,args)
         if temp !== missing
            return temp
         end
      end
   end
   return missing
end

(f::GenericFuntion)(args...) = doGenericMethod(f,args...)

#Main Project Example
# C1 = make_class(:C1,[],[:a])
# @defclass(C2,[C1],a)
# @defclass(C3,[C1,C2],b)
# c11 = make_instance(C1,:a=>3)
# c31 = make_instance(C3,:a=>2)
# set_slot!(c11,:a,3)
# get_slot(c11,:a)
# c31.b = 3
# c31.b
# @defgeneric Foo(y)
# @defmethod Foo(x::C2) = x.a
# Foo(c31)

#Extension Example
#-------------------------------------------------------------
# Added capability to support primitive types, all their super
# types (including Any) and Dictionaries.
# Important: its only supported Dictionaries: Any => Any
#--------------------------------------------------------------
# @defgeneric Bar(x)
# @defmethod Bar(x::Int) = x*x
# @defmethod Bar(s :: String) = "I am type String!"
# @defmethod Bar(x::Dict) = x[:a]
# @defmethod Bar(x::Any)= "I am type Any!"
# dicionario = Dict{Any,Any}()
# dicionario[:a]= "teste"
# Bar("Hello")
# Bar(2)
# Bar(dicionario)
# Bar(:s)
