



# #=
module ptest
using ..Acceptors
using ..ArrayViews


vec = [10, 20, 30, 40, 50, 60, 70]

array_view = ArrayView(vec, 2, 5)

eq_acc1 = EqualityAcceptor(20)
eq_acc2 = EqualityAcceptor(30)
eq_acc3 = EqualityAcceptor(10)
eq_acc4 = EqualityAcceptor(40)




# res_opt = accept(eq_acc1, array_view)
# res_opt = accept(eq_acc2, array_view)


seq_acc1 = SequenceAcceptor(eq_acc1, eq_acc2)
seq_acc2 = SequenceAcceptor(eq_acc1, eq_acc3)
seq_acc3 = SequenceAcceptor(eq_acc3, eq_acc2)

# res_opt = accept(seq_acc1, array_view)
# res_opt = accept(seq_acc2, array_view)
# res_opt = accept(seq_acc3, array_view)


choice_acc1 = ChoiceAcceptor(eq_acc1, eq_acc2)
choice_acc2 = ChoiceAcceptor(eq_acc2, eq_acc1)
choice_acc3 = ChoiceAcceptor(eq_acc2, eq_acc3)

# res_opt = accept(choice_acc1, array_view)
# res_opt = accept(choice_acc2, array_view)
# res_opt = accept(choice_acc3, array_view)


# tupseq_acc = TupleSequenceAcceptor(eq_acc1, eq_acc2, eq_acc4)
# tupseq_acc = TupleSequenceAcceptor(eq_acc1, eq_acc2, eq_acc3)
# tupseq_acc = TupleSequenceAcceptor(eq_acc2, eq_acc2, eq_acc3)
# tupseq_acc = TupleSequenceAcceptor(eq_acc1, eq_acc3, eq_acc3)

# res_opt = accept(tupseq_acc, array_view)


# nseq_acc = NSequenceAcceptor(eq_acc1, eq_acc3, eq_acc3)
# nseq_acc = NSequenceAcceptor(eq_acc1, eq_acc2, eq_acc4)

# res_opt = accept(nseq_acc, array_view)



# opt_acc = OptionalAcceptor(eq_acc1)
opt_acc = OptionalAcceptor(eq_acc2)

res_opt = accept(opt_acc, array_view)





end

# =#


