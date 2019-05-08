struct IntrospectableFunction
    name
    parameters
    body
    native_function
end

##################
# Não usar o eval#
##################

# @introspectable square(x)= x*x
square = IntrospectableFunction(:square,:(x,),:(x*x),x->x*x)

expr = :(3+1)

macro introspectable(expr)
    let name = expr.args[1].args[1],
        parameters = tuple(expr.args[1].args[2:end]...)
        :(square = IntrospectableFunction(:square,:(x,),:(x*x),x->x*x) )
    end
end

 @macroexpand @introspectable square(x)= x*x
 @introspectable power(b,e)= b^e

square.native_function(3)

power = IntrospectableFunction(:power,:(b,e),:(b^e),(b,e)->b^e)

(f::IntrospectableFunction)(args...) = f.native_function(args...)

macro reset(var)
    :($(esc(var)) = 0)
end

@macroexpand @reset(xpto)

let x = 10
println(x)
@reset(x)
println(x)
end
