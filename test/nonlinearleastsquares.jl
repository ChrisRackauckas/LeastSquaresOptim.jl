using LeastSquaresOptim, Base.Test

# simple factor model
# only problem with "real" optimization 
# nice example because J'J is not invertible
# but cholfact in sparse handles this case
function factor()
    name = "factor"
    function f!(x, fvec)
        fvec[1] = 3.0 - x[1] * x[4]
        fvec[2] = 2.0 - x[1] * x[5]
        fvec[3] = 5.0 - x[1] * x[6]

        fvec[4] = 4.5 - x[2] * x[4]
        fvec[5] = 3.2 - x[2] * x[5]
        fvec[6] = 2.0 - x[2] * x[6]

        fvec[7] = 5.0 - x[3] * x[4]
        fvec[8] = 1.3 - x[3] * x[5]
        fvec[9] = 1.5 - x[3] * x[6]
    end

    function g!(x, J)
        fill!(J, 0.0)
        J[1, 1] = -x[4]
        J[1, 4] = -x[1]
        J[2, 1] = -x[5]
        J[2, 5] = -x[1]
        J[3, 1] = -x[6]
        J[3, 6] = -x[1]

        J[4, 2] = -x[4]
        J[4, 4] = -x[2]
        J[5, 2] = -x[5]
        J[5, 5] = -x[2]
        J[6, 2] = -x[6]
        J[6, 6] = -x[2]

        J[7, 3] = -x[4]
        J[7, 4] = -x[3]
        J[8, 3] = -x[5]
        J[8, 5] = -x[3]
        J[9, 3] = -x[6]
        J[9, 6] = -x[3]
    end

    function g!(x, J::SparseMatrixCSC)
        Jvals = nonzeros(J)
        i = 0
        i += 1
        Jvals[i] = -x[4]
        i += 1
        Jvals[i] = -x[1]
        i += 1
        Jvals[i] = -x[5]
        i += 1
        Jvals[i] = -x[1]
        i += 1
        Jvals[i] = -x[6]
        i += 1
        Jvals[i] = -x[1]
        i += 1
        Jvals[i] = -x[4]
        i += 1
        Jvals[i] = -x[2]
        i += 1
        Jvals[i] = -x[5]
        i += 1
        Jvals[i] = -x[2]
        i += 1
        Jvals[i] = -x[6]
        i += 1
        Jvals[i] = -x[2]
        i += 1
        Jvals[i] = -x[4]
        i += 1
        Jvals[i] = -x[3]
        i += 1
        Jvals[i] = -x[5]
        i += 1
        Jvals[i] = -x[3]
        i += 1
        Jvals[i] = -x[6]
        i += 1
        Jvals[i] = -x[3]
    end
    x = ones(6)
    return name, f!, g!, x
end

iter = 0
for matrix in (:dense, :sparse)
    for (optimizer, optimizer_abbr) in ((LeastSquaresOptim.Dogleg(), :dl), (LeastSquaresOptim.LevenbergMarquardt(), :lm))
        factorization = matrix == :dense ? LeastSquaresOptim.QR() : LeastSquaresOptim.Cholesky()
        for (solver, solver_abbr) in ((factorization, :fact), (LeastSquaresOptim.LSMR(), :iter))
            iter += 1
            if matrix == :sparse && optimizer == LeastSquaresOptim.LevenbergMarquardt()
                continue
            else
                name, f!, g!, x = factor()
                fcur = ones(9)
                J = ones(9, 6)
                g!(x, J)
                if matrix == :sparse
                    J = sparse(J)
                end
                nls = LeastSquaresProblem(x = x, y = fcur, f! = f!, J = J, g! = g!)
                r = optimize!(nls, optimizer, solver)
                if iter == 1
                    show(r)
                end
                @printf("%-6s %4s %2s %30s %5d %5d   %5d   %10e\n", matrix, solver_abbr, optimizer_abbr, name, r.iterations, r.f_calls, r.g_calls, r.ssr)
                @test r.ssr <= 12
                @test r.converged
                end
            end
    end
end







