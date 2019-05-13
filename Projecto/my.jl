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
   end

   struct SpecificMethod
      parent
      types
      native_function
   end

#Tranlator for primitives
   const Translator = Dict{Symbol,Any}()
   Translator[:Int] = Symbol(Int)

   function make_class(name,super,fields)
      realParents = tuple(name)
      realFields = tuple(fields...)
      for sp in super
         realParents = (realParents...,getfield(sp,:hierarchy)...)
         realFields = (realFields...,getfield(sp,:fields)...)

      end

      return Class(name,realParents,realFields)
   end

   C1 = make_class(:C1,[],[:a])

   function make_instance(class,init...)
      dic = Dict{Symbol,Any}()
      for f in class.fields
         dic[f] = nothing
   end

   for p in init
      dic[p.first] = p.second
   end

   return Instance(class,dic)
end

c11 = make_instance(C1,:a => 1)
c12 = make_instance(C1)

function Base.getproperty(obj::Instance, sym::Symbol)
   dic = getfield(obj,:fields)
   if haskey(dic,sym)
      slot = get(dic,sym,nothing)
      if slot === nothing
         error("Slot $sym is missing")
      end
      return slot
   else
      error("Slot $sym is unbound")
   end
end

function Base.setproperty!(obj::Instance, sym::Symbol,x)
   dic = getfield(obj,:fields)
   if haskey(dic,sym)
      return dic[sym] = x
   else
      error("Slot $sym is unbound")
   end
end

macro defclass(name,super,fields...)
   sym = Expr(:quote,name)
   realFields=[:($(Symbol(entry))) for entry in fields]

   :($(esc(name)) = make_class($(sym),$super,$realFields))
end


@defclass(C2,[C1],c)


function get_slot(obj::Instance,sym::Symbol)
   return getproperty(obj, sym)
end

get_slot(c11,:a)

function set_slot!(obj::Instance,sym::Symbol,value)
   return setproperty!(obj, sym,value)
end

set_slot!(c11,:a,3)
get_slot(c11,:a)


macro defgeneric(expr)
   let name = expr.args[1],
      sym = Expr(:quote,name)
      parameters = (expr.args[2:end])
      meths = Dict{Tuple,SpecificMethod}()
      :($(esc(name)) = GenericFuntion($(sym),$(parameters),size($parameters,1),$meths) )
   end
end

@defgeneric Foo(y)



macro defmethod(expr)
   param_type = tuple()
   param_var = tuple()
   param = :C1
   let name = expr.args[1].args[1],
      parameters = (expr.args[1].args[2:end]),
      body =expr.args[2].args[2],
      current = 1
      quote
         if size($(parameters),1) !== $(name).num
            error("Wrong number of args")
         end
         for i = 1:$(name).num
            if $(parameters)[i].args[1] !== $(name).parameters[i]
               error("Wrong number of args")
            end
            $(param_type = tuple(param_type...,get(Translator,parameters[current].args[2],parameters[current].args[2])))
            $(param_var = tuple(param_var...,parameters[current].args[1]))
            $(current = current +1)
         end
         $(name).specific[$(param_type)] = SpecificMethod($(name),$(param_type), $(Expr(:tuple,param_var...))-> $(body))
      end
   end
end


@defmethod Foo(y::C1) = y.a+y.a
@defmethod Foo(y::Any) = y+y

function doGenericMethod(method :: GenericFuntion , args...)
   temp = []
   for arg in args

      if typeof(arg) === Instance
         dump(getfield(arg,:class))
         temp = push!(temp,getfield(arg,:class))
      else
         temp = push!(temp,(typeof(arg)))
      end

   end

   metd = lookSpecificMethod(1,method.specific,temp)
   if metd !== missing
      return metd.native_function(args...)
   else
      error("No aplicable method")
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


doGenericMethod(Foo,c11)
doGenericMethod(Foo,1)

(f::GenericFuntion)(args...) = doGenericMethod(f,args...)
c12.a = 2
c21 = make_instance(C2, :a => 2)
Foo(c21)
