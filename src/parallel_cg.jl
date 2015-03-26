function normsq{T}(x::Vector{T})
  s = zero(T)
  @inbounds @simd for i=1:length(x)
    s += x[i]*x[i]
  end
  s
end

function prod_add!(p, mult, r)
  @inbounds @simd for i=1:length(p)
    p[i] = mult*p[i] + r[i]
  end
end

function add_prod!(x, mult, v)
  @inbounds @simd for i=1:length(x)
    x[i] += mult*v[i]
  end
end

function sub_prod!(x, mult, v)
  @inbounds @simd for i=1:length(x)
    x[i] -= mult*v[i]
  end
end

## K.A -> A
function parallel_cg(x, A, b;
         tol::Real=size(A,2)*eps(), maxiter::Integer=size(A,2))
    tol = tol * norm(b)
    r = b - A * x
    p = copy(r)
    bkden = zero(eltype(x))
    err   = norm(r)
    
    for iter = 1:maxiter
        err < tol && return x, err, iter
        bknum = normsq(r)

        if iter > 1
            bk = bknum / bkden
            prod_add!(p, bk, r)
        end
        bkden = bknum

        z = A * p

        ak = bknum / dot(z, p)

        add_prod!(x, ak, p)
        sub_prod!(r, ak, z)
        
        err = norm(r)
        println(err)
    end
    x, err, maxiter
end
