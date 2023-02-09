(*
 * Defining Hexadecimal
 *)
Inductive address :=
 | Nil
 | D0 (_:address)
 | D1 (_:address)
 | D2 (_:address)
 | D3 (_:address)
 | D4 (_:address)
 | D5 (_:address)
 | D6 (_:address)
 | D7 (_:address)
 | D8 (_:address)
 | D9 (_:address)
 | Da (_:address)
 | Db (_:address)
 | Dc (_:address)
 | Dd (_:address)
 | De (_:address)
 | Df (_:address).

Fixpoint compare_address (h1 : address) (h2 : address) : bool :=
    match (h1) with
    | Nil => 
        match (h2) with
        | Nil => true
        | _ => false
        end
    | D0 (h1') => 
        match (h2) with
        | D0 (h2') => compare_address (h1') (h2')
        | _ => false
        end 
    | D1 (h1') => 
        match (h2) with
        | D1 (h2') => compare_address (h1') (h2')
        | _ => false
        end
    | D2 (h1') => 
        match (h2) with
        | D2 (h2') => compare_address (h1') (h2')
        | _ => false
        end
    | D3 (h1') => 
        match (h2) with
        | D3 (h2') => compare_address (h1') (h2')
        | _ => false
        end
    | D4 (h1') => 
        match (h2) with
        | D4 (h2') => compare_address (h1') (h2')
        | _ => false
        end
    | D5 (h1') => 
        match (h2) with
        | D5 (h2') => compare_address (h1') (h2')
        | _ => false
        end
    | D6 (h1') => 
        match (h2) with
        | D6 (h2') => compare_address (h1') (h2')
        | _ => false
        end
    | D7 (h1') => 
        match (h2) with
        | D7 (h2') => compare_address (h1') (h2')
        | _ => false
        end
    | D8 (h1') => 
        match (h2) with
        | D8 (h2') => compare_address (h1') (h2')
        | _ => false
        end
    | D9 (h1') => 
        match (h2) with
        | D9 (h2') => compare_address (h1') (h2')
        | _ => false
        end
    | Da (h1') => 
        match (h2) with
        | Da (h2') => compare_address (h1') (h2')
        | _ => false
        end
    | Db (h1') => 
        match (h2) with
        | Db (h2') => compare_address (h1') (h2')
        | _ => false
        end
    | Dc (h1') => 
        match (h2) with
        | Dc (h2') => compare_address (h1') (h2')
        | _ => false
        end
    | Dd (h1') => 
        match (h2) with
        | Dd (h2') => compare_address (h1') (h2')
        | _ => false
        end
    | De (h1') => 
        match (h2) with
        | De (h2') => compare_address (h1') (h2')
        | _ => false
        end
    | Df (h1') => 
        match (h2) with
        | Df (h2') => compare_address (h1') (h2')
        | _ => false
        end
    end.

Lemma compare_same_address : forall (addr : address),
    compare_address (addr) (addr) = true.
Proof.
    intros. induction addr as [ | l' | l' | l' | l' | l' | l' | l' | 
    l' | l' | l' | l' | l' | l' | l' | l' | l' IHl'].
    - simpl. reflexivity.
    - simpl. apply IHl'.
    - simpl. apply IHl'.
    - simpl. apply IHl'.
    - simpl. apply IHl'.
    - simpl. apply IHl'.
    - simpl. apply IHl'.
    - simpl. apply IHl'.
    - simpl. apply IHl'.
    - simpl. apply IHl'.
    - simpl. apply IHl'.
    - simpl. apply IHl'.
    - simpl. apply IHl'.
    - simpl. apply IHl'.
    - simpl. apply IHl'.
    - simpl. apply IHl'.
    - simpl. apply IHl'.
Qed.
    
