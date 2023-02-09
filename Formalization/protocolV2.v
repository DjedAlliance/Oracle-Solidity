(*
 * Importing the Libraries
 *)
Require Import Init.Decimal.
Require Import Reals.
Require Import Floats.
Require Import List.
Require Import Coq.Strings.String.
From ORACLE Require Export defs.


(*
 * HELPER FUNCTIONS
 *)
Definition max_nat (num1 : nat) (num2 : nat) : nat :=
    if (num1 <? num2)
    then
        num2
    else
        num1.

Definition min_nat (num1 : nat) (num2 : nat) : nat :=
    if (num1 <? num2)
    then
        num1
    else
        num2.

Definition get_total_revenue (state : State) : nat :=
    state.(oracleState).(totalRevenue).

Definition get_consumers (state : State) : AllConsumers :=
    state.(oracleState).(allConsumers).


Definition get_latest_write (state : State) : LatestWrite :=
    state.(oracleState).(latestWrite).


Definition get_base_fee (state : State) : BaseFee :=
    state.(oracleState).(baseFee).

Definition get_owner (state : State) : Owner :=
    state.(oracleParameters).(owner).

Definition get_description (state : State) : string :=
    state.(oracleParameters).(description).

Definition get_locking_period (state : State) : nat :=
    state.(oracleParameters).(lockingPeriod).

    
Definition get_trace (state : State) : Trace :=
    state.(trace).

(* 
 * This function checks if a consumer with the address 'consumer' exists in the target list
 *)
 Fixpoint consumer_exists (consumer : address) (type : Type) (targetList : list (address * type)) : bool :=
    match (targetList) with
    | nil => false
    | (addr, _) :: targetList' => 
        match (compare_address (addr) (consumer)) with
        | true => true
        | _ => consumer_exists (consumer) (type) (targetList')
        end
    end.


(* 
 * This function checks if the targetList is empty or not
 *)
Definition not_empty (type : Type) (targetList : list (address * type)) : Prop :=
    match targetList with
    | nil => False
    | (addr, _) :: targetList' => True
    end.

(*
 * Assuming the element already exists in the array and only one such address exists
 *)
Fixpoint modify_list (type : Type) (targetList : list (address * type)) (targetAddress : address) (elem : type) (current_list : list (address * type)) : list (address * type) :=
    match targetList with
    | nil => current_list
    | (addr, oldElem) :: targetList' => 
        if (compare_address (addr) (targetAddress))
        then
            current_list ++ ((addr, elem) :: nil) ++ targetList'
        else
            modify_list (type) (targetList') (targetAddress) (elem) (current_list ++ ((addr, oldElem) :: nil))
    end.

Fixpoint get_consumer_info (allConsumers : list (address * ConsumerInfo)) (targetAddress : address) : ConsumerInfo :=
    match allConsumers with
    | nil => 
        Build_ConsumerInfo (0) (0) (0) (0) (0)
    | (addr, info) :: allConsumers' =>
        if (compare_address (addr) (targetAddress))
        then
            info 
        else
            get_consumer_info (allConsumers') (targetAddress)
    end.

Definition get_latest_read_consumer (consumer : address) (state : State) : nat :=
    let consumerInfo := get_consumer_info (get_consumers (state)) (consumer) in
        consumerInfo.(latestRead).

Definition register_consumer (consumer : address) (consumerList : AllConsumers) (credit : nat) (latestRead : nat)
                             (weight : nat) (weightNext : nat) (weightTimelock : nat) : AllConsumers :=
    let newConsumer := Build_ConsumerInfo (credit) (latestRead) (weight) (weightNext) (weightTimelock) in
    (consumer, newConsumer) :: consumerList.


(*
 * Function Definitions
 *)

Definition constructor (owner : address) (description : string) 
                        (lockingPeriod : nat) (baseFee : nat) : State :=
    let oracleState := Build_OracleState (0 % float) (0) (0) (0) (0) (0) (baseFee) 
                        (baseFee * 3) (0) (0) (0) (0) (0) (nil) in
        let oracleParameters := Build_OracleParameters (owner) (description) (lockingPeriod) in
            Build_State (oracleState) (oracleParameters) (nil).


Definition write_data (state : State) (newData : float) (newCost : nat) (caller : address) : State :=
    let oldOracleState := state.(oracleState) in
    let oldOracleParams := state.(oracleParameters) in
    let oldTrace := state.(trace) in

    if (compare_address (oldOracleParams.(owner)) (caller))
    then
        let newOracleState := Build_OracleState (newData) (oldOracleState.(timeStamp) + 1) (oldOracleState.(totalCost) + newCost) (oldOracleState.(totalRevenue))
                                (oldOracleState.(writes) + 1) (oldOracleState.(reads)) (oldOracleState.(baseFee)) (oldOracleState.(maxFee))
                                (oldOracleState.(maxFeeNext)) (oldOracleState.(maxFeeTimeLock)) (newCost) (oldOracleState.(timeStamp) + 1) (oldOracleState.(totalCredit))
                                (oldOracleState.(allConsumers)) in
        let newEvent := DataWritten (newData) (newCost) (caller) in
        
        Build_State (newOracleState) (oldOracleParams) (oldTrace ++ (newEvent :: nil))
    else
        state.

Definition weight_of (consumer : address) (allConsumers : AllConsumers) : nat :=
    let consumerInfo := get_consumer_info (allConsumers) (consumer) in
        consumerInfo.(weight).
    

Definition fee_of (consumer : address) (weight : nat) (allConsumers : AllConsumers) (latestWrite : nat) (baseFee : nat) : nat :=
    let consumerInfo := get_consumer_info (allConsumers) (consumer) in
        if (latestWrite <? consumerInfo.(latestRead))
        then
            0
        else
            (weight * baseFee).

Definition fee_of_public (consumer : address) (state : State) : nat :=
        fee_of (consumer) (weight_of (consumer) (state.(oracleState).(allConsumers))) 
        (state.(oracleState).(allConsumers)) 
        (state.(oracleState).(latestWrite)) (state.(oracleState).(baseFee)).

Definition get_credit_consumer (consumer : address) (allConsumers : AllConsumers) : nat :=
    let consumerInfo := get_consumer_info (allConsumers) (consumer) in
        consumerInfo.(credit).
    


Definition read_data (state : State) (consumer : address) : (State * ValueOption float) :=
    let oldOracleState := state.(oracleState) in
    let oldOracleParams := state.(oracleParameters) in
    let oldTrace := state.(trace) in
    let consumerInfo := get_consumer_info (oldOracleState.(allConsumers)) (consumer) in 
    let weight := consumerInfo.(weight) in
    let fee := fee_of (consumer) (weight) (oldOracleState.(allConsumers)) 
                (oldOracleState.(latestWrite)) (oldOracleState.(baseFee)) in
    let credit := consumerInfo.(credit) in
    let data := oldOracleState.(data) in

        if (credit <? fee)
        then 
            (state, None float)
        else
            let newConsumerInfo := Build_ConsumerInfo (credit - fee) (oldOracleState.(timeStamp) + 1) (weight) (consumerInfo.(weightNext)) (consumerInfo.(weightTimeLock)) in
            let newOracleState := Build_OracleState (data) (oldOracleState.(timeStamp) + 1) (oldOracleState.(totalCost)) (oldOracleState.(totalRevenue) + fee) 
                (oldOracleState.(writes)) (oldOracleState.(reads) + weight) (oldOracleState.(baseFee)) (oldOracleState.(maxFee))
                (oldOracleState.(maxFeeNext)) (oldOracleState.(maxFeeTimeLock)) (oldOracleState.(latestCost)) (oldOracleState.(latestWrite))
                (oldOracleState.(totalCredit) - fee) (modify_list (ConsumerInfo) (oldOracleState.(allConsumers)) (consumer) (newConsumerInfo) (nil)) in
            let newState := Build_State (newOracleState) (oldOracleParams) (oldTrace ++ ((DataRead (consumer) (weight) (data)) :: nil)) in

                (newState, Some float (data)).  

Definition inspectData (caller : address) (state : State) : ValueOption float :=
    let oldOracleState := state.(oracleState) in
    let oldOracleParams := state.(oracleParameters) in

    if (compare_address (oldOracleParams.(owner)) (caller))
    then
        Some (float) (oldOracleState.(data))
    else 
        None float.

Definition schedule_weight_adjustment (consumer : address) (caller : address) (weightNext : nat) (blockTimeStamp : nat) (state : State) : State :=
    let oldOracleState := state.(oracleState) in
    let oldOracleParams := state.(oracleParameters) in 
    let oldTrace := state.(trace) in

    if (compare_address (oldOracleParams.(owner)) (caller))
    then
        let consumerInfo := get_consumer_info (oldOracleState.(allConsumers)) (consumer) in  
        let scheduleTime := (blockTimeStamp + (oldOracleParams.(lockingPeriod))) in
        let newConsumerInfo := Build_ConsumerInfo (consumerInfo.(credit)) (consumerInfo.(latestRead))
            (consumerInfo.(weight)) (weightNext) (scheduleTime) in
        let newConsumers := modify_list (ConsumerInfo) (oldOracleState.(allConsumers)) (consumer) (newConsumerInfo) (nil) in
        let newOracleState := Build_OracleState (oldOracleState.(data)) (oldOracleState.(timeStamp)) (oldOracleState.(totalCost)) (oldOracleState.(totalRevenue))
                              (oldOracleState.(writes)) (oldOracleState.(reads)) (oldOracleState.(baseFee)) (oldOracleState.(maxFee)) 
                              (oldOracleState.(maxFeeNext)) (oldOracleState.(maxFeeTimeLock)) (oldOracleState.(latestCost)) (oldOracleState.(latestWrite)) 
                              (oldOracleState.(totalCredit)) (newConsumers) in
        let newState := Build_State (newOracleState) (oldOracleParams)
                        (oldTrace ++ ((WeightAdjustmentScheduled (consumer) (caller) (weightNext) (blockTimeStamp) (scheduleTime)) :: nil)) in
        
        newState
    else
        state.


Definition adjust_weight (consumer : address) (caller : address) (blockTimeStamp : nat) (state : State) : State :=
    let oldOracleState := state.(oracleState) in
    let oldOracleParams := state.(oracleParameters) in 
    let oldTrace := state.(trace) in

    if (compare_address (oldOracleParams.(owner)) (caller))
    then
        let consumerInfo := get_consumer_info (oldOracleState.(allConsumers)) (consumer) in
            if (blockTimeStamp <? consumerInfo.(weightTimeLock))
            then
                state
            else
                let newConsumerInfo := Build_ConsumerInfo (consumerInfo.(credit)) (consumerInfo.(latestRead))
                    (consumerInfo.(weightNext)) (consumerInfo.(weightNext)) (consumerInfo.(weightTimeLock)) in
                let newConsumers := modify_list (ConsumerInfo) (oldOracleState.(allConsumers)) (consumer) (newConsumerInfo) (nil) in
                
                let newOracleState := Build_OracleState (oldOracleState.(data)) (oldOracleState.(timeStamp)) (oldOracleState.(totalCost)) (oldOracleState.(totalRevenue))
                                        (oldOracleState.(writes)) (oldOracleState.(reads)) (oldOracleState.(baseFee)) (oldOracleState.(maxFee)) 
                                        (oldOracleState.(maxFeeNext)) (oldOracleState.(maxFeeTimeLock)) (oldOracleState.(latestCost)) (oldOracleState.(latestWrite)) 
                                        (oldOracleState.(totalCredit)) (newConsumers) in
                let newState := Build_State (newOracleState) (oldOracleParams)
                (oldTrace ++ ((WeightAdjusted (consumer) (caller) (blockTimeStamp) (newConsumerInfo.(weight))) :: nil)) in

                newState
    else
        state.


Definition schedule_max_fee_adjustment (maxFeeNextNew : nat) (caller : address) (blockTimeStamp : nat) (state : State) : State :=
    let oldOracleState := state.(oracleState) in
    let oldOracleParams := state.(oracleParameters) in 
    let oldTrace := state.(trace) in

    if (compare_address (oldOracleParams.(owner)) (caller))
    then
        let newOracleState := Build_OracleState
            (oldOracleState.(data)) (oldOracleState.(timeStamp)) (oldOracleState.(totalCost)) (oldOracleState.(totalRevenue)) (oldOracleState.(writes)) 
            (oldOracleState.(reads)) (oldOracleState.(baseFee)) (oldOracleState.(maxFee)) (maxFeeNextNew) 
            (blockTimeStamp + (oldOracleParams.(lockingPeriod))) (oldOracleState.(latestCost)) (oldOracleState.(latestWrite)) 
            (oldOracleState.(totalCredit)) (oldOracleState.(allConsumers)) in
        
        let newState := Build_State (newOracleState) (oldOracleParams)
                        (oldTrace ++ ((MaxFeeAdjustmentScheduled (maxFeeNextNew) (caller) (blockTimeStamp) (blockTimeStamp + oldOracleParams.(lockingPeriod))) :: nil)) in
        
        newState
    else
        state.

Definition adjust_max_fee (caller : address) (blockTimeStamp : nat) (state : State) : State :=
    let oldOracleState := state.(oracleState) in
    let oldOracleParams := state.(oracleParameters) in 
    let oldTrace := state.(trace) in

    if (compare_address (oldOracleParams.(owner)) (caller))
    then
        if (blockTimeStamp <? oldOracleState.(maxFeeTimeLock))
        then
            state
        else
            let newOracleState := Build_OracleState
            (oldOracleState.(data)) (oldOracleState.(timeStamp)) (oldOracleState.(totalCost)) (oldOracleState.(totalRevenue)) (oldOracleState.(writes)) 
            (oldOracleState.(reads)) (oldOracleState.(baseFee)) (oldOracleState.(maxFeeNext)) (oldOracleState.(maxFeeNext)) 
            (oldOracleState.(maxFeeTimeLock)) (oldOracleState.(latestCost)) (oldOracleState.(latestWrite)) 
            (oldOracleState.(totalCredit)) (oldOracleState.(allConsumers)) in
            
            let newState := Build_State (newOracleState) (oldOracleParams) 
            (oldTrace ++ ((MaxFeeAdjusted (caller) (blockTimeStamp) (oldOracleState.(maxFeeNext))) :: nil)) in

            newState
    else
        state.



Definition adjust_base_fee (caller : address) (state : State) : State :=
    let oldOracleState := state.(oracleState) in
    let oldOracleParams := state.(oracleParameters) in 
    let oldTrace := state.(trace) in

    if (compare_address (oldOracleParams.(owner)) (caller))        
    then
        let readsDiv :=
            if (oldOracleState.(reads) =? 0)
            then
                1
            else
                oldOracleState.(reads) in
        let addCent :=
            if (((((oldOracleState.(latestCost) * oldOracleState.(writes)) + oldOracleState.(totalCost)) - oldOracleState.(totalRevenue)) mod readsDiv) =? 0)
            then
                0
            else
                1 in
        let newBaseFee := 
            if (((oldOracleState.(latestCost) * oldOracleState.(writes)) + oldOracleState.(totalCost)) <=? oldOracleState.(totalRevenue))
            then
                0
            else
                min (((((oldOracleState.(latestCost) * oldOracleState.(writes)) + oldOracleState.(totalCost)) - oldOracleState.(totalRevenue)) / readsDiv) + addCent) 
                    (oldOracleState.(maxFee)) in
        let newOracleState := Build_OracleState
        (oldOracleState.(data)) (oldOracleState.(timeStamp)) (oldOracleState.(totalCost)) (oldOracleState.(totalRevenue)) (0) (0) (newBaseFee) 
        (oldOracleState.(maxFee)) (oldOracleState.(maxFeeNext)) (oldOracleState.(maxFeeTimeLock)) (oldOracleState.(latestCost)) 
        (oldOracleState.(latestWrite)) (oldOracleState.(totalCredit)) (oldOracleState.(allConsumers)) in

        let newState := Build_State (newOracleState) (oldOracleParams)
        (oldTrace ++ ((BaseFeeAdjusted (caller) (oldOracleState.(writes)) (oldOracleState.(reads)) (newBaseFee)) :: nil)) in

        newState
    else
        state.

Definition deposit_credit (consumer : address) (state : State) (deposit : nat) : State :=
    let oldOracleState := state.(oracleState) in
    let oldOracleParams := state.(oracleParameters) in 
    let oldTrace := state.(trace) in
    let consumerInfo := get_consumer_info (oldOracleState.(allConsumers)) (consumer) in
    let newAllConsumers :=
        if (consumerInfo.(weight) =? 0)
        then
            register_consumer (consumer) (oldOracleState.(allConsumers)) (deposit) (0) (1) (0) (0)
        else
            let newConsumerInfo := Build_ConsumerInfo ((consumerInfo.(credit) + deposit))
                (consumerInfo.(latestRead)) (consumerInfo.(weight)) (consumerInfo.(weightNext))
                (consumerInfo.(weightTimeLock)) in
            modify_list (ConsumerInfo) (oldOracleState.(allConsumers)) (consumer) (newConsumerInfo) (nil) in
    
    let newOracleState := Build_OracleState
    (oldOracleState.(data)) (oldOracleState.(timeStamp)) (oldOracleState.(totalCost)) (oldOracleState.(totalRevenue)) (oldOracleState.(writes)) (oldOracleState.(reads)) 
    (oldOracleState.(baseFee)) (oldOracleState.(maxFee)) (oldOracleState.(maxFeeNext)) (oldOracleState.(maxFeeTimeLock)) (oldOracleState.(latestCost)) 
    (oldOracleState.(latestWrite)) (oldOracleState.(totalCredit) + deposit) (newAllConsumers) in
    
    let newState := Build_State (newOracleState) (oldOracleParams)
    (oldTrace ++ ((CreditDeposited (consumer) (deposit)) :: nil)) in

    newState.


Definition withdraw_credit (amount : nat) (caller : address) (state : State) : State :=
    let oldOracleState := state.(oracleState) in
    let oldOracleParams := state.(oracleParameters) in 
    let oldTrace := state.(trace) in
    let consumerInfo := get_consumer_info (oldOracleState.(allConsumers)) (caller) in

    if (consumerInfo.(credit) <? amount)
    then
        state
    else
    let newConsumerInfo := Build_ConsumerInfo ((consumerInfo.(credit) - amount)) (consumerInfo.(latestRead))
                            (consumerInfo.(weight)) (consumerInfo.(weightNext)) (consumerInfo.(weightTimeLock)) in
    let newConsumers := modify_list (ConsumerInfo) (oldOracleState.(allConsumers)) (caller) (newConsumerInfo) (nil) in
    let newOracleState := Build_OracleState
    (oldOracleState.(data)) (oldOracleState.(timeStamp)) (oldOracleState.(totalCost)) (oldOracleState.(totalRevenue)) (oldOracleState.(writes)) (oldOracleState.(reads)) 
    (oldOracleState.(baseFee)) (oldOracleState.(maxFee)) (oldOracleState.(maxFeeNext)) (oldOracleState.(maxFeeTimeLock)) (oldOracleState.(latestCost)) 
    (oldOracleState.(latestWrite)) (oldOracleState.(totalCredit) - amount) (newConsumers) in
    
    let newState := Build_State (newOracleState) (oldOracleParams)
    (oldTrace ++ ((CreditWithdrawn (amount) (caller)) :: nil)) in

    newState.

Definition withdraw (receiver : address) (amount : nat) (caller : address) (state : State) : State :=
    let oldOracleState := state.(oracleState) in
    let oldOracleParams := state.(oracleParameters) in 
    let oldTrace := state.(trace) in

    if (compare_address (oldOracleParams.(owner)) (caller))
    then
        if ((oldOracleState.(totalRevenue) - oldOracleState.(totalCredit)) <? amount)
        then
            state
        else
            let newOracleState := Build_OracleState
            (oldOracleState.(data)) (oldOracleState.(timeStamp)) (oldOracleState.(totalCost)) (oldOracleState.(totalRevenue) - amount) (oldOracleState.(writes)) (oldOracleState.(reads)) 
            (oldOracleState.(baseFee)) (oldOracleState.(maxFee)) (oldOracleState.(maxFeeNext)) (oldOracleState.(maxFeeTimeLock)) (oldOracleState.(latestCost)) 
            (oldOracleState.(latestWrite)) (oldOracleState.(totalCredit)) (oldOracleState.(allConsumers)) in
            
            let newState := Build_State (newOracleState) (oldOracleParams)
            (oldTrace ++ ((RevenueWithdrawn (receiver) (amount) (caller)) :: nil)) in

            newState
    else
        state.

Definition reset_cost_and_revenue (state : State) : State :=
    let oldOracleState := state.(oracleState) in
    let oldOracleParams := state.(oracleParameters) in 
    let oldTrace := state.(trace) in
    let (newTotalCost, newTotalRevenue) := 
        if (oldOracleState.(totalRevenue) <? oldOracleState.(totalCost))
        then
            ((oldOracleState.(totalCost) - oldOracleState.(totalRevenue)), 0)
        else
            (0, (oldOracleState.(totalRevenue) - oldOracleState.(totalCost))) in
    let newOracleState := Build_OracleState
    (oldOracleState.(data)) (newTotalCost) (oldOracleState.(timeStamp)) (newTotalRevenue) (oldOracleState.(writes)) (oldOracleState.(reads)) 
    (oldOracleState.(baseFee)) (oldOracleState.(maxFee)) (oldOracleState.(maxFeeNext)) (oldOracleState.(maxFeeTimeLock)) (oldOracleState.(latestCost)) 
    (oldOracleState.(latestWrite)) (oldOracleState.(totalCredit)) (oldOracleState.(allConsumers)) in
            
    let newState := Build_State (newOracleState) (oldOracleParams)
    (oldTrace ++ ((Reset (oldOracleState.(totalCost)) (oldOracleState.(totalRevenue))) :: nil)) in

    newState.


Definition execute (state : State) (event : Events) : State :=
    match event with
    | DataWritten (newData) (newCost) (caller) => write_data (state) (newData) (newCost) (caller)
    | DataRead (consumer) (_) (_) => 
        let (newState, _) := read_data (state) (consumer)
        in
            newState
    | WeightAdjustmentScheduled (consumer) (caller) (weightNext) (timeStamp) (_) => 
        schedule_weight_adjustment (consumer) (caller) (weightNext) (timeStamp) (state)
    | WeightAdjusted (consumer) (caller) (timeStamp) (_) => adjust_weight (consumer) (caller) (timeStamp) (state)
    | MaxFeeAdjustmentScheduled (maxFeeNextNew) (caller) (timeStamp) (_) => schedule_max_fee_adjustment (maxFeeNextNew) (caller) (timeStamp) (state)
    | MaxFeeAdjusted (caller) (timeStamp) (_) => adjust_max_fee (caller) (timeStamp) (state)
    | BaseFeeAdjusted (caller) (_) (_) (_) => adjust_base_fee (caller) (state)
    | CreditDeposited (consumer) (deposit) => deposit_credit (consumer) (state) (deposit)
    | CreditWithdrawn (amount) (caller) => withdraw_credit (amount) (caller) (state)
    | RevenueWithdrawn (receiver) (amount) (caller) => withdraw (receiver) (amount) (caller) (state)
    | Reset (_) (_) => reset_cost_and_revenue (state)
    end.