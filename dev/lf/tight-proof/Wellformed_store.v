Set Implicit Arguments.

Require Import LibLN.
Require Import Coq.Program.Equality.
Require Import Definitions.
Require Import Weakening.

(* ###################################################################### *)
(** ** Well-formed store *)

Lemma wf_sto_to_ok_G: forall s G,
  wf_sto G s -> ok G.
Proof. intros. induction H; jauto. Qed.

Hint Resolve wf_sto_to_ok_G.

Lemma ctx_binds_to_sto_binds_raw: forall s G x T,
  wf_sto G s ->
  binds x T G ->
  exists G1 G2 v, G = G1 & (x ~ T) & G2 /\ binds x v s /\ ty_trm ty_precise sub_general G1 (trm_val v) T.
Proof.
  introv Wf Bi. gen x T Bi. induction Wf; intros.
  + false* binds_empty_inv.
  + unfolds binds. rewrite get_push in *. case_if.
    - inversions Bi. exists G (@empty typ) v.
      rewrite concat_empty_r. auto.
    - specialize (IHWf _ _ Bi). destruct IHWf as [G1 [G2 [ds' [Eq [Bi' Tyds]]]]].
      subst. exists G1 (G2 & x ~ T) ds'. rewrite concat_assoc. auto.
Qed.

Lemma sto_binds_to_ctx_binds_raw: forall s G x v,
  wf_sto G s ->
  binds x v s ->
  exists G1 G2 T, G = G1 & (x ~ T) & G2 /\ ty_trm ty_precise sub_general G1 (trm_val v) T.
Proof.
  introv Wf Bi. gen x v Bi. induction Wf; intros.
  + false* binds_empty_inv.
  + unfolds binds. rewrite get_push in *. case_if.
    - inversions Bi. exists G (@empty typ) T.
      rewrite concat_empty_r. auto.
    - specialize (IHWf _ _ Bi). destruct IHWf as [G1 [G2 [T0' [Eq Ty]]]].
      subst. exists G1 (G2 & x ~ T) T0'. rewrite concat_assoc. auto.
Qed.

Lemma typing_implies_bound: forall m1 m2 G x T,
  ty_trm m1 m2 G (trm_var (avar_f x)) T ->
  exists S, binds x S G.
Proof.
  intros. remember (trm_var (avar_f x)) as t.
  induction H;
    try solve [inversion Heqt];
    try solve [inversion Heqt; eapply IHty_trm; eauto];
    try solve [inversion Heqt; eapply IHty_trm1; eauto].
  - inversion Heqt. subst. exists T. assumption.
Qed.

Lemma corresponding_types: forall G s x T,
  wf_sto G s ->
  binds x T G ->
  ((exists S U t, binds x (val_lambda S t) s /\
                  ty_trm ty_precise sub_general G (trm_val (val_lambda S t)) (typ_all S U) /\
                  T = typ_all S U) \/
   (exists S ds, binds x (val_new S ds) s /\
                 ty_trm ty_precise sub_general G (trm_val (val_new S ds)) (typ_bnd S) /\
                 T = typ_bnd S)).
Proof.
  introv H Bi. induction H.
  - false* binds_empty_inv.
  - unfolds binds. rewrite get_push in *. case_if.
    + inversions Bi. inversion H2; subst.
      * left. exists T0. exists U. exists t.
        split. auto. split.
        apply weaken_ty_trm. assumption. apply ok_push. eapply wf_sto_to_ok_G. eassumption. assumption.
        reflexivity.
      * right. exists T0. exists ds.
        split. auto. split.
        apply weaken_ty_trm. assumption. apply ok_push. eapply wf_sto_to_ok_G. eassumption. assumption.
        reflexivity.
      * assert (exists x, trm_val v = trm_var (avar_f x)) as A. {
          apply H3. reflexivity.
        }
        destruct A as [? A]. inversion A.
    + specialize (IHwf_sto Bi).
      inversion IHwf_sto as [IH | IH].
      * destruct IH as [S [U [t [IH1 [IH2 IH3]]]]].
        left. exists S. exists U. exists t.
        split. assumption. split.
        apply weaken_ty_trm. assumption. apply ok_push. eapply wf_sto_to_ok_G. eassumption. assumption.
        assumption.
      * destruct IH as [S [ds [IH1 [IH2 IH3]]]].
        right. exists S. exists ds.
        split. assumption. split.
        apply weaken_ty_trm. assumption. apply ok_push. eapply wf_sto_to_ok_G. eassumption. assumption.
        assumption.
Qed.

Lemma sto_binds_to_ctx_binds: forall G s x v,
  wf_sto G s -> binds x v s -> exists S, binds x S G.
Proof.
  introv Hwf Bis.
  remember Hwf as Hwf'. clear HeqHwf'.
  apply sto_binds_to_ctx_binds_raw with (x:=x) (v:=v) in Hwf.
  destruct Hwf as [G1 [G2 [T [EqG Hty]]]].
  subst.
  exists T.
  eapply binds_middle_eq. apply wf_sto_to_ok_G in Hwf'.
  apply ok_middle_inv in Hwf'. destruct Hwf'. assumption.
  assumption.
Qed.

Lemma wf_sto_val_new_in_G: forall G s x T ds,
  wf_sto G s ->
  binds x (val_new T ds) s ->
  binds x (typ_bnd T) G.
Proof.
  introv Hwf Bis.
  assert (exists S, binds x S G) as Bi. {
    eapply sto_binds_to_ctx_binds; eauto.
  }
  destruct Bi as [S Bi].
  destruct (corresponding_types Hwf Bi).
  - destruct H as [? [? [? [Bis' _]]]].
    unfold binds in Bis'. unfold binds in Bis. rewrite Bis in Bis'. inversion Bis'.
  - destruct H as [T' [ds' [Bis' [Hty Heq]]]].
    unfold binds in Bis'. unfold binds in Bis. rewrite Bis' in Bis. inversions Bis.
    assumption.
Qed.

Lemma val_new_typing: forall G s x T ds,
  wf_sto G s ->
  binds x (val_new T ds) s ->
  ty_trm ty_precise sub_general G (trm_val (val_new T ds)) (typ_bnd T).
Proof.
  introv Hwf Bis.
  assert (exists T, binds x T G) as Bi. {
    eapply sto_binds_to_ctx_binds; eauto.
  }
  destruct Bi as [T0 Bi].
  destruct (corresponding_types Hwf Bi).
  - destruct H as [S [U [t [Bis' [Ht EqT]]]]].
    false.
  - destruct H as [T' [ds' [Bis' [Ht EqT]]]]. subst.
    unfold binds in Bis. unfold binds in Bis'. rewrite Bis' in Bis.
    inversion Bis. subst.
    assumption.
Qed.
