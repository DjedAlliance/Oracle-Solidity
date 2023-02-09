(*
* Importing the Libraries
*)
Require Import Init.Decimal.
Require Import Reals.
Require Import Floats.
Require Import List.
Require Import Coq.Strings.String.
From ORACLE Require Export Hexadecimal.

(*
* IMPORTANT
* weight is interpreted as float
* reads and writes : float
* What to do if the address doesn't exist in the mapping?
*)



Inductive ValueOption (type : Type) : Type :=
    | Some (val : type)
    | None.


Inductive Events : Type :=
    | DataWritten (newData : float) (newCost : nat) (caller : address)
    | DataRead (consumer : address) (weight : nat) (data : float)
    | WeightAdjustmentScheduled (consumer : address) (caller : address) (weightNext : nat) (timeStamp : nat) (weightTimelock : nat) 
    | WeightAdjusted (consumer : address) (caller : address) (timeStamp : nat) (weight : nat)
    | MaxFeeAdjustmentScheduled (maxFeeNextNew : nat) (caller : address) (timeStamp : nat) (maxFeeTimelock : nat) 
    | MaxFeeAdjusted (caller : address) (timeStamp : nat) (maxFee : nat)
    | BaseFeeAdjusted (caller : address) (writes : nat) (reads : nat) (fee : nat)
    | CreditDeposited (consumer : address) (deposit : nat)
    | CreditWithdrawn (amount : nat) (caller : address)
    | RevenueWithdrawn (receiver : address) (amount : nat) (caller : address)
    | Reset (cost : nat) (revenue : nat).

Definition Trace : Type :=
    list (Events).

Definition Credit := nat.
Definition LatestRead := nat.
Definition Weight := nat.
Definition WeightNext := nat.
Definition WeightTimeLock := nat.

Record ConsumerInfo :=
{
    credit : nat;
    latestRead : nat;
    weight : nat;
    weightNext : nat;
    weightTimeLock : nat
    
}.

Definition Owner := address.
Definition Data := float.
Definition TimeStamp := nat.
Definition TotalCost := nat.
Definition TotalRevenue := nat.
Definition Writes := nat.
Definition Reads := nat.
Definition BaseFee := nat.
Definition MaxFee := nat.
Definition MaxFeeNext := nat.
Definition MaxFeeTimeLock := nat.
Definition LatestCost := nat.
Definition LatestWrite := nat.
Definition TotalCredit := nat.
Definition AllConsumers := list (address * ConsumerInfo).

(*
* Definitions
*)


Record OracleState :=
{
    data : Data;
    timeStamp : TimeStamp;
    totalCost : TotalCost;
    totalRevenue : TotalRevenue;
    writes : Writes;
    reads : Reads;
    baseFee : BaseFee;
    maxFee : MaxFee;
    maxFeeNext : MaxFeeNext;
    maxFeeTimeLock : MaxFeeTimeLock;
    latestCost : LatestCost;
    latestWrite : LatestWrite;
    totalCredit : TotalCredit;
    allConsumers : AllConsumers
}.

Record OracleParameters :=
{
    owner : Owner;
    description : string;
    lockingPeriod : nat
}.

Record State :=
{
    oracleState : OracleState;
    oracleParameters : OracleParameters;
    trace : Trace
}.
