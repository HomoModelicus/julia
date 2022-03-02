
# =========================================================================== #
# Training
# =========================================================================== #

struct TrainingOptions
    learning_rate::Float64
    batch_size::Int
    max_iter::Int
    max_norm::Float64
end
function TrainingOptions(;
    learning_rate = 0.1,
    batch_size = 2,
    max_iter = 100,
    max_norm = 1.0)
    return TrainingOptions(learning_rate, batch_size, max_iter, max_norm)
end
