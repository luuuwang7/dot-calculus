Set Implicit Arguments.

Require Import LibLN.
Require Import Coq.Program.Equality.
Require Import Definitions.
Require Import Inert_types.
Require Import Some_lemmas.
Require Import Narrowing.

(* ****************************************** *)
(* Invertible to precise *)

Lemma invertible_to_precise_typ_dec: forall G p A S U,
    inert G ->
    G |-## p : typ_rcd { A >: S <: U } ->
    exists T,
      G |-! trm_path p : typ_rcd { A >: T <: T } /\
      G |-# T <: U /\
      G |-# S <: T.
Proof.
  introv HG Ht.
  dependent induction Ht.
  - lets Hp: (precise_dec_typ_inv HG H). subst.
    exists U. split*.
  - specialize (IHHt A T U0 HG eq_refl). destruct IHHt as [V [Hx [Hs1 Hs2]]].
    exists V. split*.
Qed.

Lemma invertible_to_precise_trm_dec: forall G p a m T,
    inert G ->
    G |-## p : typ_rcd { a [m] T } ->
    exists T' m',
      G |-! trm_path p : typ_rcd { a [m'] T' } /\
      (m = strong -> m' = strong /\ T = T') /\
      G |-# T' <: T.
Proof.
  introv Hi Ht. dependent induction Ht.
  - (* t_pt_precise *)
    exists T m. auto.
  - (* t_pt_dec_trm *)
    specialize (IHHt _ _ _ Hi eq_refl). destruct IHHt as [V [m [Hp [Eq Hs]]]].
    exists V m. split*. split. intros F. inversion F. apply* subtyp_trans_t.
  - (* t_pt_dec_trm_strong *)
    specialize (IHHt _ _ _ Hi eq_refl). destruct IHHt as [V [m [Hp [Eq Hs]]]].
    specialize (Eq eq_refl). destruct Eq as [Eq1 Eq2]. subst.
    exists V strong. split*.
Qed.

Lemma invertible_to_precise_typ_all: forall G p S T,
    inert G ->
    G |-## p : typ_all S T ->
    exists S' T' L,
      G |-! trm_path p : typ_all S' T' /\
      G |-# S <: S' /\
      (forall y,
          y \notin L ->
              G & y ~ S |- T' ||^ y <: T ||^ y).
Proof.
  introv Hi Ht. dependent induction Ht.
  - exists S T (dom G); auto.
  - specialize (IHHt _ _ Hi eq_refl).
    destruct IHHt as [S' [T' [L' [Hpt [HSsub HTsub]]]]].
    exists S' T' (dom G \u L \u L').
    split; auto.
    assert (Hsub2 : G |-# typ_all S0 T0 <: typ_all S T) by (apply* subtyp_all_t). split.
    + eapply subtyp_trans_t; eauto.
    + intros y Fr.
      assert (Hok: ok (G & y ~ S)) by auto using ok_push, inert_ok.
      apply tight_to_general in H; auto.
      assert (Hnarrow: G & y ~ S |- T' ||^ y <: T0 ||^ y).
      { eapply narrow_subtyping; auto using subenv_last. }
      eauto.
Qed.

Lemma invertible_to_precise_sngl: forall G p q,
    inert G ->
    G |-## p: typ_sngl q ->
    G |-! trm_path p: typ_sngl q.
Proof.
  introv Hi Hp. dependent induction Hp; eauto.
Qed.

(*
Lemma invertible_lemma:
  (forall G t T,
      G |-# t: T -> forall p,
      inert G ->
      t = trm_path p ->
      G |-# p \||/ ->
      G |-## p: T) /\
  (forall G T U,
      G |-# T <: U -> forall p,
      inert G ->
      G |-## p: T ->
      G |-## p: U) /\
  (forall G p,
      G |-# p \||/ -> True).
Proof.
  apply ts_mutind_ts; intros; eauto.
Admitted.
 *)

Lemma invertible_sub_closure: forall G p T U,
  inert G ->
  G |-## p : T ->
  G |-# T <: U ->
  G |-## p : U.
Proof.
  introv Hi HT Hsub. gen p. induction Hsub; introv HT; eauto.
  - (* subtyp_bot_t *)
    inversions HT. false* precise_bot_false.
  - (* subtyp_and1_t *)
    inversion* HT.
  - (* subtyp_and2_t *)
    inversion* HT.
  - (* subtyp_sel2t *)
    inversions HT.
    + (* ty_path_i *)
      false* precise_psel_false.
    + (* subtyp_sel_i *)
      lets Hu: (inert_unique_tight_bounds Hi H H6). subst*.
    + (* subtyp_sel1_t *)
      lets Hu: (p_sngl_unique Hi H3 H). inversion Hu. (*
      inversions H7. false* precise_psel_false.
      lets Hu: (inert_unique_tight_bounds Hi H9 H). subst*.
      false* H6. *)
  - (* subtyp_sel2_t *)
    inversions HT.
    + false* precise_psel_false.
    + lets Hu: (p_sngl_unique Hi H H7). inversion Hu.
    + lets Hu: (p_sngl_unique Hi H H4). inversions Hu. assumption.
  - (* subtyp_sngl_sel2_t *)
    inversions HT.
    + false* precise_psel_false.
    + lets Hs: (subtyp_sel_i H4 H7 H8).
      destruct (classicT (p = q)) as [Heq | Hneq].
      * subst*.
      * apply* subtyp_sngl_i.
    + destruct (classicT (p = q)) as [Heq | Hneq]. subst*. apply* subtyp_sngl_i.
Qed.

Lemma invertible_lemma: forall G p T,
    inert G ->
    G |-# trm_path p: T ->
    G |-# p \||/ ->
    G |-## p: T.
Proof.
 introv Hi Hp. gen T. dependent induction p.
 - introv Hp Hn. destruct a as [b | x]. inversion Hn.
   dependent induction Hp; eauto.
   * specialize (IHHp _ Hi eq_refl Hn). inversions IHHp.
     apply ty_rec_elim_p in H. apply* ty_path_i. rewrite* <- open_var_path_typ_eq.
   * specialize (IHHp _ Hi eq_refl Hn). apply* invertible_sub_closure.
 - specialize (IHp Hi).
   introv Ht Hn.
   dependent induction Ht; try specialize (IHHt p t IHp Hi eq_refl Hn); eauto.
   * inversions Hn.
     lets IHp2: (IHp _ Ht H4). specialize (IHp _ H1 H4). inversions IHp.
     destruct (invertible_to_precise_trm_dec Hi IHp2) as [V [m [Hp [_ Hs]]]].
     destruct (p_rcd_unique Hi H Hp). subst. apply ty_fld_elim_p in H; auto.
     apply ty_path_i in Hp. apply* invertible_sub_closure.
   * inversions IHHt. apply ty_rec_elim_p in H. apply* ty_path_i.
   * apply* invertible_sub_closure.
Qed.

Lemma invertible_sub_closure_v: forall G v T U,
  inert G ->
  G |-##v v: T ->
  G |-# T <: U ->
  G |-##v v : U.
Proof.
  introv Hgd HT Hsub.
  dependent induction Hsub; eauto; inversions HT; try solve [inversion H]; try assumption.
  - inversions H1.
  - lets Hb: (inert_unique_tight_bounds Hgd H H6). subst*.
  - Admitted.

Lemma invertible_lemma_v : forall G v T,
    inert G ->
    G |-# trm_val v : T ->
    G |-##v v : T.
Proof.
  introv Hgd Hty.
  dependent induction Hty; eauto.
  specialize (IHHty _ Hgd eq_refl).
  apply* invertible_sub_closure_v.
Qed.
