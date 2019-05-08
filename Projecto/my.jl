   struct Class
      name :: Symbol
      hierarchy
      fields:: Tuple
   end # struct

   struct Instance
      class::Class
      fields::Dict
   end # struct


   function make_class(name,super,fields)
      realFields = tuple(fields...)
      for sp in super
         realFields = (realFields...,getfield(sp,:fields)...)

      end
      return Class(name,tuple(super...),realFields)
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
   sym = Meta.parse(":$name")
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
