(*
 * Necessary Imports
 *)
Require Import Init.Decimal.
Require Import Reals.
Require Import Floats.
Require Import List.
Require Import Coq.Strings.String.
From ORACLE Require Export protocolV2.


(*
 * THEOREMS AND SPECIFICATIONS
 *)


(*
 * Theorem 1: All actions on the oracle maintain the non-negativity of credit of all
 *            all consumers
 *)



(*
 * This function describes what it means for the credit for all the consumers to be 
 * non negative. The input parameter 'allConsumers' is the list of consumer info obtained
 * from the Oracle.
 *)
Fixpoint credit_non_negative_all_consumers (allConsumers : AllConsumers) : Prop :=
    match (allConsumers) with
    | nil => True
    | (_, info) :: allConsumers' => ((0 <=? info.(credit)) = true) /\ 
                                    (credit_non_negative_all_consumers (allConsumers'))
    end.

(*
 * This states in terms of a proposition what it means for the credit of
 * a single consumer to be non-negative.
 *)
Definition credit_non_negative_single_consumer (info : ConsumerInfo) : Prop :=
    ((0 <=? info.(credit))) = true.



(*
 * This proves that if the propoerty holds individually for the sublists l1 and l2
 *)
Theorem credit_non_negative_helper2 : forall (l1 : AllConsumers) (l2 : AllConsumers),
    credit_non_negative_all_consumers (l1 ++ l2) <-> ((credit_non_negative_all_consumers (l1)) /\ (credit_non_negative_all_consumers (l2))).
Proof.
    intros. induction l1 as [ | (addr, info) l1' IHl1']. split. 
    - simpl. intros. split. reflexivity. apply H.
    - simpl. intros. destruct H. apply H0.
    - split.
     + intros. split. simpl. simpl in H. split. destruct H.
        apply H. destruct H. apply IHl1' in H0. destruct H0. apply H0.
        simpl in H. destruct H. apply IHl1' in H0. destruct H0. apply H1.
     + intros. simpl. split.
        simpl in H. destruct H. destruct H.
            apply H.
        simpl in H. destruct H. destruct H. apply IHl1'. split.
        apply H1. apply H0.
Qed.


(*
 * This theorem proves that if the initial list of consumer info (allConsumers) satisfies the
 * credit non-negative property, then modifying one member of the list maintains the property
 * given that the new consumer info (elem) has non-negative credit. Since the function 'modify_list'
 * is tail_recursive we can assume that 'currModList' satisfies the credit non-negative property for
 * all the consumers
 *)
Theorem credit_non_negative_helper1 : 
    forall (consumer : address) (elem : ConsumerInfo) (allConsumers : AllConsumers)
    (currModList : AllConsumers),
    (credit_non_negative_single_consumer (elem)) -> 
    (credit_non_negative_all_consumers (allConsumers)) ->
    (credit_non_negative_all_consumers (currModList)) ->
    credit_non_negative_all_consumers (modify_list (ConsumerInfo) (allConsumers) (consumer) (elem) (currModList)).
Proof.
    intros consumer elem allConsumers. induction allConsumers as [ | (addr, info) l' IHl'].
    - intros. simpl. apply H1.
    - intros. simpl.
      case_eq (compare_address (addr) (consumer)).
       + intros. apply credit_non_negative_helper2. split.
        * apply H1.
        * simpl. split. unfold credit_non_negative_single_consumer in H. apply H.
          simpl in H0. destruct H0. apply H3.
       + intros. simpl in H0. destruct H0. apply IHl'.
         apply H.
         apply H3. apply credit_non_negative_helper2.
         split. apply H1. simpl. split. apply H0. reflexivity.
Qed.
        
 
(*
 * This is the main theorem. It proves that given an event and state of the oracle
 * if the credit of all the consumers is non negative then after the event the credit
 * still remains non negative for all the consumers
 *
 * The proof cases on the event
 *)
Theorem credit_non_negative : forall (event : Events) (state : State),
    (credit_non_negative_all_consumers (get_consumers (state))) -> 
    (credit_non_negative_all_consumers (get_consumers (execute (state) (event)))).
Proof.
    intros. destruct state. destruct oracleState. destruct oracleParameters.
    destruct event. simpl in H.
    + simpl. unfold write_data. case_eq (compare_address owner caller).
        intros. simpl. rewrite -> H0. unfold get_consumers. simpl. unfold get_consumers in H. simpl in H. apply H.
        intros. simpl. rewrite -> H0. unfold get_consumers. simpl. unfold get_consumers in H. simpl in H. apply H.
    + simpl. unfold read_data. simpl. simpl.
      case_eq (credit (get_consumer_info allConsumers consumer) <?
      fee_of consumer
      (defs.weight (get_consumer_info allConsumers consumer))
      allConsumers latestWrite baseFee).
        intros. simpl. simpl in H. apply H.
        intros. simpl. apply credit_non_negative_helper1.
            unfold credit_non_negative_single_consumer.
            simpl. reflexivity.
            simpl in H. apply H.
            simpl. reflexivity.
    + simpl. unfold schedule_weight_adjustment. simpl. case_eq (compare_address owner caller).
        intros. simpl. apply credit_non_negative_helper1.
            unfold credit_non_negative_single_consumer.
            simpl. reflexivity.
            simpl in H. apply H.
            simpl. reflexivity.
            intros. simpl. simpl in H. apply H.
    + simpl. unfold adjust_weight. simpl. case_eq (compare_address owner caller).
      case_eq (timeStamp0 <? weightTimeLock (get_consumer_info allConsumers consumer)).
        intros. simpl. simpl in H. apply H.
        intros. simpl. apply credit_non_negative_helper1.
            unfold credit_non_negative_single_consumer.
            simpl. reflexivity.
            simpl in H. apply H.
            simpl. reflexivity.
            intros. simpl. simpl in H. apply H.
    + simpl. unfold schedule_max_fee_adjustment. simpl. case_eq (compare_address owner caller).
        intros. simpl. simpl in H. apply H.
        intros. simpl. simpl in H. apply H.
    + simpl. unfold adjust_max_fee. simpl. case_eq (compare_address owner caller).
        intros. case_eq (timeStamp0 <? maxFeeTimeLock).
            intros. simpl. simpl in H. apply H.
            intros. simpl. simpl in H. apply H.
        intros. simpl. simpl in H. apply H.
    + simpl. unfold adjust_base_fee. simpl. case_eq (compare_address owner caller).
        intros. simpl. simpl in H. apply H.
        intros. simpl. simpl in H. apply H.
    + simpl. simpl in H. unfold deposit_credit. simpl. case_eq (weight (get_consumer_info allConsumers consumer) =? 0).
        intros. simpl. split.
            reflexivity.
            simpl in H. apply H.
        intros. apply credit_non_negative_helper1.
            simpl. unfold credit_non_negative_single_consumer. simpl. reflexivity.
            apply H.
            simpl. reflexivity.
    + simpl. unfold withdraw_credit. simpl. case_eq (credit (get_consumer_info allConsumers caller) <? amount).
        intros. simpl. simpl in H. apply H.
        intros. simpl. apply credit_non_negative_helper1.
            unfold credit_non_negative_single_consumer. simpl. reflexivity.
            simpl in H. apply H.
            simpl. reflexivity.
    + simpl. unfold withdraw. simpl. case_eq (compare_address owner caller).
        intros. case_eq (totalRevenue - totalCredit <? amount).
            simpl. intros. simpl in H. apply H.
            intros. simpl. simpl in H. apply H.
            intros. simpl. simpl in H. apply H.
    + simpl. unfold reset_cost_and_revenue. simpl. case_eq (totalRevenue <? totalCost).
        simpl. intros. simpl in H. apply H.
        simpl. intros. simpl in H. apply H.
Qed.
            


(*
 * Theorem 2: 
 * Main Idea: Every consumer pays exactly once for every new data publish. Between any 2 data written
 * events in the trace is the consumer reads data more than once, he/she is to be charged only once
 *)



(*
 * This function looks at the trace and accumulates the events in the 'currList' until a 'DataWritten'
 * event is encountered or we reach the end of the trace. The function is tail recursive.
 * trace : The trace which is investigated
 * currState : The state of the oracle just before the event at the head of the trace
 * currList : The tail recursive list which accumulates the events 
 *)

Fixpoint split_trace_helper (trace : Trace) (currState : State) (currList : list (State * Events)) : list (State * Events) :=
    match trace with
    | nil => currList
    | e :: trace' =>
        let newState := execute (currState) (e)
        in
            match e with
            | DataWritten (_) (_) (_) => currList
            | _ => split_trace_helper (trace') (newState) (currList ++ ((currState, e) :: nil))
            end
    end.


(*
 * This function looks at the trace and creates a lists of lists. The sublists are the record of events between two 'DataWritten'
 * events in the trace. The function returns a list of slices where each slice is a record of events between two 'DataWritten'
 * events
 * trace : The trace to be investigated
 * currState : This is the state of the Oracle before the event at the head of the trace
 * subLists : This list accumulates the slices as the function is tail recursive. This list is returned when we reach the end of the trace
 *)
Fixpoint split_trace (trace : Trace) (currState : State) (subLists : list (list (State * Events))) : list (list (State * Events)) :=
    match trace with
    | nil => subLists
    | e :: trace' =>
        let newState := execute (currState) (e)
        in
            match e with
            | DataWritten (_) (_) (_) => split_trace (trace') (newState) (subLists ++ ((split_trace_helper (trace') (newState) (nil)) :: nil))
            | _ => split_trace (trace') (newState) (subLists)
            end
    end.


Fixpoint split_trace_correct_prop (mergeSlice : list (State * Events)) (trace : list (Events)) : Prop :=
    match trace with
    | nil => 
        match mergeSlice with
        | nil => True
        | _ => False
        end
    | e :: trace' => 
        match e with
        | DataWritten (_) (_) (_) => split_trace_correct_prop (mergeSlice) (trace')
        | _ => 
            match mergeSlice with
            | nil => False
            | (_, event) :: mergeSlice' => (event = e) /\ (split_trace_correct_prop (mergeSlice') (trace'))
            end
        end
    end.

Fixpoint my_remove_event (trace : list (Events)) : list (Events) :=
    match trace with
    | nil => nil
    | e :: trace' =>
        match e with
        | DataWritten (_) (_) (_) => my_remove_event (trace')
        | _ => e :: (my_remove_event (trace'))
        end
    end.

Fixpoint my_remove_state (splitList : list (State * Events)) : list (Events) :=
    match splitList with
    | nil => nil
    | (state, event) :: splitList' => event :: (my_remove_state (splitList'))
    end.

Theorem my_remove_event_removes_datawritten :
    forall (trace1 : list (Events)) (trace2 : list (Events)),
    my_remove_event (trace1 ++ trace2) = my_remove_event (trace1) ++ my_remove_event (trace2).

Proof.
    intros. induction trace1 as [ | e l' IHl'].
    - simpl. reflexivity.
    - simpl. destruct e.
        + apply IHl'.
        + rewrite -> IHl'. reflexivity.
        + rewrite -> IHl'. reflexivity.
        + rewrite -> IHl'. reflexivity.
        + rewrite -> IHl'. reflexivity.
        + rewrite -> IHl'. reflexivity.
        + rewrite -> IHl'. reflexivity.
        + rewrite -> IHl'. reflexivity.
        + rewrite -> IHl'. reflexivity.
        + rewrite -> IHl'. reflexivity.
        + rewrite -> IHl'. reflexivity.
Qed.


(*
 * This function takes in a slice (record of events between 2 arbitrary DataWritten events) and 
 * returns a Proposition. This proposition states what it means for every consumer to pay
 * exactly once between 2 DataWritten events. The function cases on the event in the tuple (state, event)
 * If the event is DataRead and the latestRead of the consumer is greater than the latestWrite then
 * the consumer has already paid before and should not pay. If not, then the consumer is reading the
 * data for the first time and should pay
 *)
Fixpoint all_consumers_pay_once_slice (slice : list (State * Events)) : Prop :=
    match (slice) with
    | nil => True
    | (state, event) :: slice' => 
        match (event) with
        | DataRead (consumer) (Weight) (data) =>
            let latestWrite := get_latest_write (state) in
            let consumerInfo := get_consumer_info (get_consumers (state)) (consumer) in
            let baseFee := get_base_fee (state) in
            let weightConsumer := consumerInfo.(weight) in
            let feeConsumer := ((weightConsumer * baseFee)) in
            let latestReadConsumer := consumerInfo.(latestRead) in
            let (totalRevenueBefore, totalRevenueAfter) := 
                (get_total_revenue (state), get_total_revenue (execute (state) (event))) in

                (((latestWrite <? latestReadConsumer) = true) ->
                ((totalRevenueAfter = totalRevenueBefore) /\ 
                 (all_consumers_pay_once_slice (slice')))) 
                /\ 
                (((latestWrite <? latestReadConsumer) = false) ->
                (((((consumerInfo.(credit) <? feeConsumer) = true) -> 
                    totalRevenueAfter = totalRevenueBefore) 
                    /\ 
                    (((consumerInfo.(credit) <? feeConsumer) = false) -> 
                    totalRevenueAfter = (totalRevenueBefore + feeConsumer))) /\ 
                (all_consumers_pay_once_slice (slice'))))
        | _ => all_consumers_pay_once_slice (slice')
        end
    end.

 
(*
 * It makes sure that the above property holds for all the slices in the list 
 * returned by 'split_trace' (splitList). It applied the 'rev' function on the slice
 * because initially every slice is ordered from least recent to most recent event
 * (least recent) at the head of the list. It makes more sense later in the inductive proof
 * to reason about the reversed list 
 *)    
Fixpoint all_consumers_pay_once (splitList : list (list (State * Events))) : Prop :=
    match (splitList) with
    | nil => True
    | slice :: splitList' => (all_consumers_pay_once_slice (rev (slice))) 
                            /\ (all_consumers_pay_once (splitList'))
    end.


(*
 * This function tells us what it means for there to be no DataWritten event 
 * in an arbitrary slice. Since we are slicing at DataWritten events exclusive, there
 * should be no DataWritten events in a slice
 *)
Fixpoint no_data_written_in_slice (slice : list (State * Events)) : Prop :=
    match slice with
    | nil => True
    | (_, event) :: eventHistory' => 
        match (event) with
        | DataWritten (_) (_) (_) => False
        | _ => True /\ (no_data_written_in_slice (eventHistory'))
        end
    end.


(*
 * This function tells us what it means for there to be no DataWritten event 
 * in the list of slices. From here, the list returned by 'split_trace' will be referred
 * as the list of slices.
 *)
Fixpoint no_data_written_subLists (subList : list (list (State * Events))) : Prop :=
    match subList with
    | nil => True
    | slice :: subList' => (no_data_written_in_slice (slice)) /\ 
                            (no_data_written_subLists (subList'))
    end.


(*
 * This is part of the main proof. We prove that if we have no 'DataWritten' event in a slice
 * then all consumers pay exactly once in the slice.
 *
 * Proof Idea: We do induction on the slice. In the inducive case we do a case by case analysis of 
 * the event in the tuple (state, event). The case for 'DataRead' is the hard one and requires elaborate proof.
 * The rest of the cases are easy and have exactly the same proof.
 *)
Theorem consumer_pays_once_slice : forall (slice : list (State * Events)),
    no_data_written_in_slice (slice) -> all_consumers_pay_once_slice (slice).
Proof.
    intros. induction slice as [ | (s, e) l' IHl'].
    - simpl. reflexivity.
    - destruct e.
     + simpl. inversion H.
     + simpl. split.
      * intros. split. 
            unfold read_data. unfold fee_of. simpl.
            case_eq (latestWrite (oracleState s) <?
            latestRead
            (get_consumer_info (allConsumers (oracleState s)) consumer)).
                intros. simpl. apply Nat.add_0_r.

                intros. unfold get_latest_write in H0. unfold get_consumers in H0.
                simpl in H0. rewrite -> H1 in H0. discriminate H0.

            apply IHl'. unfold no_data_written_in_slice in H. destruct H. 
            fold no_data_written_in_slice in H1. apply H1.
      * intros. split.
            split. 
                intros. unfold read_data. unfold fee_of. simpl.
                case_eq (latestWrite (oracleState s) <?
                latestRead
                (get_consumer_info (allConsumers (oracleState s)) consumer)).
                    intros. unfold get_consumers in H0. unfold get_latest_write in H0. rewrite -> H2 in H0.
                    discriminate.

                    intros.
                    case_eq (credit (get_consumer_info (allConsumers (oracleState s)) consumer) <?
                    defs.weight (get_consumer_info (allConsumers (oracleState s)) consumer) *
                    baseFee (oracleState s)).
                        intros. reflexivity.

                        intros. unfold get_consumers in H1. unfold get_latest_write in H1.
                        unfold get_base_fee in H1.
                        rewrite -> H3 in H1. discriminate H1.

                intros. unfold read_data. unfold fee_of. simpl.
                case_eq (latestWrite (oracleState s) <?
                latestRead
                (get_consumer_info (allConsumers (oracleState s)) consumer)).
                    intros. unfold get_consumers in H0. unfold get_latest_write in H0.
                    rewrite -> H2 in H0. discriminate.

                    intros.
                    case_eq (credit (get_consumer_info (allConsumers (oracleState s)) consumer) <?
                    defs.weight (get_consumer_info (allConsumers (oracleState s)) consumer) *
                    baseFee (oracleState s)).
                        intros. unfold get_consumers in H1. unfold get_latest_write in H1.
                        unfold get_base_fee in H1. rewrite -> H3 in H1. discriminate H1.

                        intros. unfold get_total_revenue. simpl. reflexivity.

            apply IHl'. unfold no_data_written_in_slice in H. destruct H.
            fold no_data_written_in_slice in H1. apply H1.
    + simpl. apply IHl'. 
      unfold no_data_written_in_slice in H. destruct H.
      fold no_data_written_in_slice in H0. apply H0.
    + simpl. apply IHl'. 
      unfold no_data_written_in_slice in H. destruct H.
      fold no_data_written_in_slice in H0. apply H0.
    + simpl. apply IHl'. 
      unfold no_data_written_in_slice in H. destruct H.
      fold no_data_written_in_slice in H0. apply H0.
    + simpl. apply IHl'. 
      unfold no_data_written_in_slice in H. destruct H.
      fold no_data_written_in_slice in H0. apply H0.
    + simpl. apply IHl'. 
      unfold no_data_written_in_slice in H. destruct H.
      fold no_data_written_in_slice in H0. apply H0.
    + simpl. apply IHl'. 
      unfold no_data_written_in_slice in H. destruct H.
      fold no_data_written_in_slice in H0. apply H0.
    + simpl. apply IHl'. 
      unfold no_data_written_in_slice in H. destruct H.
      fold no_data_written_in_slice in H0. apply H0.
    + simpl. apply IHl'. 
      unfold no_data_written_in_slice in H. destruct H.
      fold no_data_written_in_slice in H0. apply H0.
    + simpl. apply IHl'. 
      unfold no_data_written_in_slice in H. destruct H.
      fold no_data_written_in_slice in H0. apply H0.
Qed.



(*
 * This just proves that if a given property (no_data_written_in_slice) holds for two lists (l1, l2) appended
 * together than the given property also holds for the two lists individually
 *)
Theorem no_data_written_rev_split :
    forall (l1 : list (State * Events)) (l2 : list (State * Events)),
    no_data_written_in_slice (l1 ++ l2) -> no_data_written_in_slice (l1) /\ no_data_written_in_slice (l2).
Proof.
    intros. induction l1 as [ | (s, e) l' IHl'].
    - simpl in H. split.
        simpl. reflexivity.
        apply H.
    - destruct e.
        + contradiction.
        + simpl in H. destruct H. simpl. split. split.
            reflexivity. apply IHl' in H0. destruct H0. apply H0. apply IHl' in H0. destruct H0. apply H1.
        + simpl in H. destruct H. simpl. split. split.
            reflexivity. apply IHl' in H0. destruct H0. apply H0. apply IHl' in H0. destruct H0. apply H1.
        + simpl in H. destruct H. simpl. split. split.
            reflexivity. apply IHl' in H0. destruct H0. apply H0. apply IHl' in H0. destruct H0. apply H1.
        + simpl in H. destruct H. simpl. split. split.
            reflexivity. apply IHl' in H0. destruct H0. apply H0. apply IHl' in H0. destruct H0. apply H1.
        + simpl in H. destruct H. simpl. split. split.
            reflexivity. apply IHl' in H0. destruct H0. apply H0. apply IHl' in H0. destruct H0. apply H1.
        + simpl in H. destruct H. simpl. split. split.
            reflexivity. apply IHl' in H0. destruct H0. apply H0. apply IHl' in H0. destruct H0. apply H1.
        + simpl in H. destruct H. simpl. split. split.
            reflexivity. apply IHl' in H0. destruct H0. apply H0. apply IHl' in H0. destruct H0. apply H1.
        + simpl in H. destruct H. simpl. split. split.
            reflexivity. apply IHl' in H0. destruct H0. apply H0. apply IHl' in H0. destruct H0. apply H1.
        + simpl in H. destruct H. simpl. split. split.
            reflexivity. apply IHl' in H0. destruct H0. apply H0. apply IHl' in H0. destruct H0. apply H1.
        + simpl in H. destruct H. simpl. split. split.
            reflexivity. apply IHl' in H0. destruct H0. apply H0. apply IHl' in H0. destruct H0. apply H1.
Qed.

(*
 * This just proves that if a given property (no_data_written_in_slice) holds for two lists (l1, l2) individually
 * together than the given property also holds for the two lists appended
 *)
Theorem no_data_written_in_slice_proof_helper1 :
    forall (l1 : list (State * Events)) (l2 : list (State * Events)),
    (no_data_written_in_slice (l1) /\ no_data_written_in_slice (l2)) -> no_data_written_in_slice (l1 ++ l2).

Proof.
    intros. induction l1 as [ | e l1' IHl1'].
    - simpl. simpl in H. destruct H. apply H0.
    - destruct e. destruct e.
       simpl. simpl in H. destruct H. contradiction.
       simpl. simpl in H. destruct H. destruct H. split. reflexivity. apply IHl1'. split. apply H1. apply H0.
       simpl. simpl in H. destruct H. destruct H. split. reflexivity. apply IHl1'. split. apply H1. apply H0.
       simpl. simpl in H. destruct H. destruct H. split. reflexivity. apply IHl1'. split. apply H1. apply H0.
       simpl. simpl in H. destruct H. destruct H. split. reflexivity. apply IHl1'. split. apply H1. apply H0.
       simpl. simpl in H. destruct H. destruct H. split. reflexivity. apply IHl1'. split. apply H1. apply H0.
       simpl. simpl in H. destruct H. destruct H. split. reflexivity. apply IHl1'. split. apply H1. apply H0.
       simpl. simpl in H. destruct H. destruct H. split. reflexivity. apply IHl1'. split. apply H1. apply H0.
       simpl. simpl in H. destruct H. destruct H. split. reflexivity. apply IHl1'. split. apply H1. apply H0.
       simpl. simpl in H. destruct H. destruct H. split. reflexivity. apply IHl1'. split. apply H1. apply H0.
       simpl. simpl in H. destruct H. destruct H. split. reflexivity. apply IHl1'. split. apply H1. apply H0.
Qed.  


(*
 * This states if there are no DataWritten events in rev (slice) then there are no
 * DataWritten events in the slice as well
 *)
Theorem no_data_written_rev :
    forall (slice : list (State * Events)),
    no_data_written_in_slice (rev (slice)) -> no_data_written_in_slice (slice).
Proof.
    intros. induction slice as [ | (s, e) l' IHl'].
    - simpl. reflexivity.
    - simpl. simpl in H. apply no_data_written_rev_split in H. destruct e. 
        + destruct H. simpl in H0. apply H0.
        + split. reflexivity. apply IHl'. destruct H. apply H.
        + split. reflexivity. apply IHl'. destruct H. apply H.
        + split. reflexivity. apply IHl'. destruct H. apply H.
        + split. reflexivity. apply IHl'. destruct H. apply H.
        + split. reflexivity. apply IHl'. destruct H. apply H.
        + split. reflexivity. apply IHl'. destruct H. apply H.
        + split. reflexivity. apply IHl'. destruct H. apply H.
        + split. reflexivity. apply IHl'. destruct H. apply H.
        + split. reflexivity. apply IHl'. destruct H. apply H.
        + split. reflexivity. apply IHl'. destruct H. apply H.
Qed.


(*
 * This states that if there are no DataWritten events in the list of slices (splitList) then
 * all consumers pay exactly once for all the slices
 *)
Theorem consumers_pay_once :  
    forall (splitList : list (list (State * Events))),
    no_data_written_subLists (splitList) -> all_consumers_pay_once (splitList).

Proof.
    intros. induction splitList as [ | x l' IHl'].
    - simpl. reflexivity.
    - simpl. split.
      simpl in H. destruct H. apply consumer_pays_once_slice. apply no_data_written_rev. rewrite -> rev_involutive. apply H.
      apply IHl'. simpl in H. destruct H. apply H0.
Qed.


(*
 * This states that if the property no_data_written_subLists holds for two lists of slices (l1, l2) individually
 * then the property also holds for the two lists appended together.
 *)
Theorem no_data_written_when_list_split_helper1 :
    forall (l1 : list (list (State * Events))) (l2 : list (list (State * Events))),
    (no_data_written_subLists (l1) /\ no_data_written_subLists (l2)) -> no_data_written_subLists (l1 ++ l2).

Proof.
    intros. induction l1 as [ | e l1' IHl1'].
    - simpl. simpl in H. destruct H. apply H0.
    - destruct e.
     + simpl. simpl in H. destruct H. split.
        reflexivity.
        apply IHl1'. split. destruct H. apply H1. apply H0. 
     + destruct p. destruct e0.
       simpl. simpl in H. destruct H. destruct H. contradiction.
       simpl. simpl in H. destruct H. destruct H. split. split. reflexivity. destruct H. apply H2. apply IHl1'. split. apply H1. apply H0.
       simpl. simpl in H. destruct H. destruct H. split. split. reflexivity. destruct H. apply H2. apply IHl1'. split. apply H1. apply H0.
       simpl. simpl in H. destruct H. destruct H. split. split. reflexivity. destruct H. apply H2. apply IHl1'. split. apply H1. apply H0.
       simpl. simpl in H. destruct H. destruct H. split. split. reflexivity. destruct H. apply H2. apply IHl1'. split. apply H1. apply H0.
       simpl. simpl in H. destruct H. destruct H. split. split. reflexivity. destruct H. apply H2. apply IHl1'. split. apply H1. apply H0.
       simpl. simpl in H. destruct H. destruct H. split. split. reflexivity. destruct H. apply H2. apply IHl1'. split. apply H1. apply H0.
       simpl. simpl in H. destruct H. destruct H. split. split. reflexivity. destruct H. apply H2. apply IHl1'. split. apply H1. apply H0.
       simpl. simpl in H. destruct H. destruct H. split. split. reflexivity. destruct H. apply H2. apply IHl1'. split. apply H1. apply H0.
       simpl. simpl in H. destruct H. destruct H. split. split. reflexivity. destruct H. apply H2. apply IHl1'. split. apply H1. apply H0.
       simpl. simpl in H. destruct H. destruct H. split. split. reflexivity. destruct H. apply H2. apply IHl1'. split. apply H1. apply H0.
Qed.

      

(*
 * This proves that assuming we have no data written events in the slice given by 'sliceSoFar' then
 * we will have no data written events in the slice returned by split_trace_helper called on the trace, startState and the sliceSoFar
 *)
Theorem no_data_written_in_slice_proof :
    forall (trace : list (Events)) (startState : State) (sliceSoFar : list (State * Events)),
    no_data_written_in_slice (sliceSoFar) -> no_data_written_in_slice (split_trace_helper (trace) (startState) (sliceSoFar)).

Proof.
    intros trace. induction trace as [ | e l' IHl'].
    - simpl. intros. apply H.
    - intros. destruct e.
        + simpl. apply H.
        + simpl. apply IHl'. apply no_data_written_in_slice_proof_helper1. split. apply H. simpl. split. reflexivity. reflexivity.
        + simpl. apply IHl'. apply no_data_written_in_slice_proof_helper1. split. apply H. simpl. split. reflexivity. reflexivity.
        + simpl. apply IHl'. apply no_data_written_in_slice_proof_helper1. split. apply H. simpl. split. reflexivity. reflexivity.
        + simpl. apply IHl'. apply no_data_written_in_slice_proof_helper1. split. apply H. simpl. split. reflexivity. reflexivity.
        + simpl. apply IHl'. apply no_data_written_in_slice_proof_helper1. split. apply H. simpl. split. reflexivity. reflexivity.
        + simpl. apply IHl'. apply no_data_written_in_slice_proof_helper1. split. apply H. simpl. split. reflexivity. reflexivity.
        + simpl. apply IHl'. apply no_data_written_in_slice_proof_helper1. split. apply H. simpl. split. reflexivity. reflexivity.
        + simpl. apply IHl'. apply no_data_written_in_slice_proof_helper1. split. apply H. simpl. split. reflexivity. reflexivity.
        + simpl. apply IHl'. apply no_data_written_in_slice_proof_helper1. split. apply H. simpl. split. reflexivity. reflexivity.
        + simpl. apply IHl'. apply no_data_written_in_slice_proof_helper1. split. apply H. simpl. split. reflexivity. reflexivity.
Qed.


(*
 * This proves that assuming we have no data written events in the list of slices given by 'splitsSoFar', we will have no
 * data written events in the list of slices returned by split_trace called on trace, startState and splitsSoFar
 *)
Theorem no_data_written_when_list_split :
    forall (trace : list (Events)) (startState : State) (splitsSoFar : list (list (State * Events))),
    no_data_written_subLists (splitsSoFar) -> no_data_written_subLists (split_trace (trace) (startState) (splitsSoFar)).

Proof.
    intros trace. induction trace as [ | e l' IHl'].
    - simpl. intros. apply H.
    - intros. destruct e.
     + simpl. apply IHl'. simpl. apply no_data_written_when_list_split_helper1. split. apply H. simpl. split. 
       apply no_data_written_in_slice_proof. simpl. reflexivity. reflexivity.
     + simpl. apply IHl'. apply H.
     + simpl. apply IHl'. apply H.
     + simpl. apply IHl'. apply H.
     + simpl. apply IHl'. apply H.
     + simpl. apply IHl'. apply H.
     + simpl. apply IHl'. apply H.
     + simpl. apply IHl'. apply H.
     + simpl. apply IHl'. apply H.
     + simpl. apply IHl'. apply H.
     + simpl. apply IHl'. apply H.
Qed.
       

(*
 * This theorem closes the proof. It says that given some state and baseFee (The baseFee is supposed to be the 
 * starting baseFee when initialising the Oracle),
 * all consumers pay exactly once in the list of slices returned by split_trace called on the trace of the state given. 
 * The split_trace function needs the state of the Oracle just before the event at the head of the trace. Since
 * we look at the full trace we need the initial state of the Oracle. To get that state we can call the constructor function
 * by getting the required parameters. However we also need the initial baseFee. There is no way to get the baseFee based on the 
 * current implementation, therefore baseFee is provided as a parameter
 *)
Theorem all_consumers_pay_once_proof :
    forall (state : State) (baseFee : nat),
    all_consumers_pay_once (split_trace (get_trace (state)) (constructor (get_owner (state)) (get_description (state)) (get_locking_period (state)) (baseFee)) (nil)).

Proof.
    intros. destruct state. destruct oracleParameters.
    simpl. apply consumers_pay_once. apply no_data_written_when_list_split. simpl. reflexivity.
Qed.