







struct RawEquation
    lhs::Vector{Token}
    rhs::Vector{Token}

    function RawEquation(lhs, rhs)
        return new(lhs, rhs)
    end
end


# function to_string(eq::RawEquation, text)
#     first = eq.lhs[1].first
#     last  = eq.rhs[end].last
#     str   = String( text[first:last] )
#     return str
# end




struct BinaryTreeEquation
    lhs::BinaryTreeNode
    rhs::BinaryTreeNode
    fcn::BinaryTreeNode
    symbols::Vector{Symbol}
    der_symbols::Vector{Symbol}
end



struct OneSidedEquation
    fcn::BinaryTreeNode
    algebraic_variables::Vector{ClassVariable}
    der_variables::Vector{ClassVariable}
end



struct OneSidedEquationSystem
    equations::Vector{BinaryTreeNode}
    algebraic_variables::Vector{ClassVariable}
    der_variables::Vector{ClassVariable}

    
end





