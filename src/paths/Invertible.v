Set Implicit Arguments.

Require Import LibLN.
Require Import Coq.Program.Equality.
Require Import Definitions.
Require Import Inert_types.
Require Import Some_lemmas.
Require Import Narrowing.

(* ****************************************** *)
(* Invertable to precise *)

Lemma invertible_to_precise_typ_dec: forall G p A S U,
    inert G ->
    G |-# p \||/ ->
    G |-## p : typ_rcd { A >: S <: U } ->
    exists T,
      G |-! trm_path p : typ_rcd { A >: T <: T } /\
      G |-# T <: U /\
      G |-# S <: T.
Proof.
  introv HG Hn Ht.
  dependent induction Ht.
  - lets Hp: (precise_dec_typ_inv HG H). subst.
    exists U. split*.
  - specialize (IHHt A T U0 HG Hn eq_refl). destruct IHHt as [V [Hx [Hs1 Hs2]]].
    exists V. split*.
Qed.

Lemma invertible_to_precise_trm_dec: forall G p a m T,
    inert G ->
    G |-# p \||/ ->
    G |-## p : typ_rcd { a [m] T } ->
    exists T' m',
      G |-! trm_path p : typ_rcd { a [m'] T' } /\
      (m = strong -> m' = strong /\ T = T') /\
      G |-# T' <: T.
Proof.
  introv Hi Hn Ht. dependent induction Ht.
  - (* t_pt_precise *)
    exists T m. auto.
  - (* t_pt_dec_trm *)
    specialize (IHHt _ _ _ Hi Hn eq_refl). destruct IHHt as [V [m [Hp [Eq Hs]]]].
    exists V m. split*. split. intros F. inversion F. apply* subtyp_trans_t.
  - (* t_pt_dec_trm_strong *)
    specialize (IHHt _ _ _ Hi Hn eq_refl). destruct IHHt as [V [m [Hp [Eq Hs]]]].
    specialize (Eq eq_refl). destruct Eq as [Eq1 Eq2]. subst.
    exists V strong. split*.
Qed.

Lemma invertible_to_precise_typ_all: forall G p S T,
    inert G ->
    G |-# p \||/ ->
    G |-## p : typ_all S T ->
    exists S' T' L,
      G |-! trm_path p : typ_all S' T' /\
      G |-# S <: S' /\
      (forall y,
          y \notin L ->
              G & y ~ S |- T' ||^ y <: T ||^ y).
Proof.
  introv Hi Hn Ht. dependent induction Ht.
  - exists S T (dom G); auto.
  - specialize (IHHt _ _ Hi Hn eq_refl).
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

Lemma invertable_to_tight: forall G p T,
    G |-## p : T ->
    G |-# trm_path p : T.
Proof.
  introv Hi. induction Hi; eauto.
  - apply* precise_to_tight.
  - apply tight_to_general in IHHi. apply typing_implies_bound in IHHi. destruct IHHi. apply* ty_sngl_intro_t.
  - admit.
Qed.

Lemma invertible_sub_closure: forall G p T U,
  inert G ->
  G |-## p : T ->
  G |-# T <: U ->
  G |-## p : U.
Proof.
  introv Hi HT Hsub.
  dependent induction Hsub; eauto.
  - inversions HT. false* precise_bot_false.
  - inversion* HT.
  - inversion* HT.
  - inversions HT.
    + false *precise_psel_false.
    + pose proof (inert_unique_tight_bounds Hi H H6). subst. assumption.
    + admit.
  - admit.
  - admit.
Qed.

Lemma normalizing_to_invertible_var: forall G x T,
    inert G ->
    G |-#n p_var (avar_f x): T ->
    G |-## p_var (avar_f x): T.
Proof.
  introv Hi Ht. dependent induction Ht; eauto; specialize (IHHt _ Hi eq_refl).
  - inversions IHHt. apply ty_rec_elim_p in H.
    apply* ty_path_i. rewrite* <- open_var_path_typ_eq.
  - apply* invertible_sub_closure.
Qed.

Lemma avar_typing_false: forall G b T,
    G |-#n p_var (avar_b b) : T -> False.
Proof.
  introv Ht. dependent induction Ht; eauto.
Qed.

Lemma normalizing_to_invertible: forall G p T,
    inert G ->
    G |-#n p: T ->
    G |-## p: T.
Proof.
  introv Hi Ht.
  dependent induction p; eauto.
  * destruct a as [b | x].
    - false* avar_typing_false.
    - apply* normalizing_to_invertible_var.
  * dependent induction Ht; eauto.
    - inversions H. lets IHp2: (IHp _ Hi Ht).
      (* O:
         Could we use H2 and IHp2 here to deduce U=T, since there is no subtyping
         inside "typ_rcd {_ [strong] _}" ? *)

      (* M:
         We can't, because we don't know anything about tight typing.
         Just like with general typing, we can't reason about it without converting it
         to another typing mode. So we would need some IH that we could apply to it,
         but we don't have that here *)
Admitted.

Lemma tight_to_normalizing_var: forall G x T,
    inert G ->
    G |-# trm_path (p_var (avar_f x)) : T ->
    G |-#n p_var (avar_f x): T.
Proof.
  introv Hi Ht. dependent induction Ht; eauto.
Qed.

Lemma precise_to_normalizing: forall G p T,
    G |-! trm_path p: T ->
    G |-# p \||/ ->
    G |-#n p: T.
Proof.
  introv H Hn. dependent induction H; eauto.
  specialize (IHty_trm_p _ eq_refl). apply ty_fld_elim_path_n in IHty_trm_p; auto.
  inversion* Hn.
Qed.

Lemma normalizing_sub_closure: forall G p T U,
    inert G ->
    G |-#n p: T ->
    G |-# T <: U ->
    G |-#n p: U.
Proof.
  introv Hi Ht Hs. dependent induction Hs; eauto.
Qed.

Lemma both: forall G p,
    inert G ->
    ( forall T, G |-#n p: T -> G |-## p: T) /\
    ( forall T, G |-# trm_path p: T -> G |-# p \||/ -> G |-#n p: T)
.
Proof.
 introv Hi.
 dependent induction p.
 - admit. (* variables, hopefully easy *)
   -
     destruct (IHp Hi) as [NI TN].
     split.
     +
       introv Ht. dependent induction Ht; eauto.
       *
         specialize (IHHt p t IHp Hi NI TN).
         inversions H.
         specialize (TN _ H2 H5).
         remember NI as NI2. clear HeqNI2.
         specialize (NI _ TN).
         specialize (NI2 _ Ht).
         (* Now can we get T=U from
  NI : G |-## p : typ_rcd {t [strong] U}
  NI2 : G |-## p : typ_rcd {t [strong] T}
?
*)
         assert (T=U) by admit. subst.
         (* Should be easy now. *)
         admit.
       * admit.
       * admit.
     +
       introv Ht Hn. clear IHp Hi.
       dependent induction Ht; eauto.
       *
         inversions Hn.
         remember TN as TN2. clear HeqTN2.
         specialize (TN _ H1 H4).
         specialize (TN2 _ Ht H4).
         remember NI as NI2. clear HeqNI2.
         specialize (NI _ TN).
         specialize (NI2 _ TN2).
         (* Now can we get T=U from
  NI : G |-## p : typ_rcd {t [strong] U}
  NI2 : G |-## p : typ_rcd {t [gen] T}
?
*)
         admit.
Qed.

Lemma direct: forall G p,
    inert G ->
    ( forall T, G |-# trm_path p: T -> G |-# p \||/ -> G |-## p: T)
.
Proof.
 introv Hi.
 dependent induction p.
 - admit. (* variables, hopefully easy *)
 - specialize (IHp Hi).
   introv Ht Hn.
   dependent induction Ht; try specialize (IHHt p t IHp Hi eq_refl Hn); eauto.
   *
     inversions Hn.
     remember IHp as IHp2. clear HeqIHp2.
     specialize (IHp _ H1 H4).
     specialize (IHp2 _ Ht H4).
     (* Now use
  IHp : G |-## p : typ_rcd {t [strong] U}
  IHp2 : G |-## p : typ_rcd {t [gen] T}
*)
     admit.
   * admit.
   * admit.
Qed.

Lemma tight_to_normalizing: forall G p T,
    inert G ->
    G |-# trm_path p: T ->
    G |-# p \||/ ->
    G |-#n p: T.
Proof.
  introv Hi Hp Hn. gen T. induction p.
  - destruct a as [b | x]. inversion Hn. intros. apply* tight_to_normalizing_var.
  - introv Ht. assert (G |-# p \||/) as Hnp by inversion* Hn.
    specialize (IHp Hnp). dependent induction Ht; eauto.
    destruct p as [[b | x] | p].
    (* M:
       this destruct was a mistake: I thought it would help me in the second case
       to apply the IH, but I still can't apply it. So I shouldn't be destructing,
       and we will not be able to apply the IH. This means that we could just do
       inversion Ht (above) *)
    * inversion Hnp.
    * apply tight_to_normalizing_var in Ht; auto.
      inversion Hn; subst.
      specialize (IHp _ H1).
      lets Hti: (normalizing_to_invertible Hi Ht).
      lets Hpi: (normalizing_to_invertible Hi IHp).
      destruct (invertible_to_precise_trm_dec Hi Hnp Hti) as [T' [mT [PrecT [_ HsT]]]].
      destruct (invertible_to_precise_trm_dec Hi Hnp Hpi) as [U' [mU [PrecU [modeU _]]]].
      specialize (modeU eq_refl). destruct modeU. subst.

      (* O:
         From PrecT and PrecU, can we now discover some useful relationship between T' and U'? *)
      (* M:
         Yes: *)
      destruct (p_rcd_unique Hi PrecT PrecU). subst.
      apply ty_fld_elim_p in PrecT; auto. apply precise_to_normalizing in PrecT; auto.
      apply* normalizing_sub_closure.
    * lets Hpt0: (IHp _ Ht). inversions Hn. specialize (IHp _ H1).
Qed.

Lemma invertible_lemma_var : forall G U x,
    inert G ->
    G |-# trm_path (p_var (avar_f x)) : U ->
    G |-## p_var (avar_f x) : U.
Proof.
  introv Hi Ht. dependent induction Ht; auto; try (specialize (IHHt _ Hi eq_refl)).
  - inversions IHHt; auto. rewrite* <- open_var_path_typ_eq.
  - apply* ty_sngl_i.
  - apply* invertible_sub_closure.
Qed.

Lemma invertible_lemma :
  (forall G t T, G |-# t: T -> forall p,
    t = trm_path p ->
    inert G ->
    norm_t G t ->
    G |-## p: T) /\
  (forall G t, norm_t G t ->
    inert G ->
    norm_p G t).
Proof.
  apply ts_mutind_t; intros; try (inversions H);
    try solve [inversion H0 || inversion H1]; eauto.
  - inversions H0. inversions H2. specialize (H _ eq_refl H1 H8).
    apply invertible_to_precise_trm_dec in H; auto. destruct H as [V [m [Hp [_ Hs]]]].
    apply invertible_lemma_var in H5; auto. apply invertible_to_precise_trm_dec in H5; auto.
    destruct H5 as [T' [m' [Hp' [Heq Hs']]]]. specialize (Heq eq_refl). destruct Heq. subst.
    lets Hu: (p_rcd_unique H1 Hp' Hp). destruct Hu. subst.
    apply ty_fld_elim_p in Hp'; auto. apply t_pt_precise in Hp'. apply* invertible_sub_closure.
    apply precise_to_general in Hp'. apply typing_implies_bound in Hp'. destruct Hp'.
    apply* norm_path_p.
  - inversions H1. specialize (H0 H2).
    assert (G |-# p \||/) as Hp by (inversion* n).
    specialize (H _ eq_refl H2 Hp).
    apply invertible_to_precise_trm_dec in H; auto.
    destruct H as [T' [m' [Ht [Heq  Hsx]]]]. specialize (Heq eq_refl). destruct Heq. subst.
    inversions H0.
    destruct (p_rcd_unique H2 Ht H5) as [_ Heq]. subst.
    apply ty_fld_elim_p in H5; auto. apply* norm_path_p.
  - inversions H0. specialize (H _ eq_refl H1 H2). apply* t_pt_bnd.
  - inversions H0. specialize (H _ eq_refl H1 H2). inversions H. auto.
    rewrite* <- open_var_path_typ_eq.
  - subst. specialize (H _ eq_refl H1 H2). apply* invertible_sub_closure.
  - subst. specialize (H _ eq_refl H1 n). apply invertible_to_precise_trm_dec in H; auto.
    destruct H as [V [m [Hp [Heq Hs]]]]. specialize (Heq eq_refl). destruct Heq. subst.
    apply* norm_path_p.
 Qed.

Lemma invertible_lemma_typ: forall G p T,
    G |-# trm_path p: T ->
    inert G ->
    G |-# p \||/ ->
    G |-## p: T.
Proof. intros. apply* invertible_lemma. Qed.

Lemma tight_possible_types_closure_tight_v: forall G v T U,
  inert G ->
  tight_pt_v G v T ->
  G |-# T <: U ->
  G |-##v v : U.
Proof.
  introv Hgd HT Hsub.
  dependent induction Hsub; eauto; inversions HT; try solve [inversion H]; try assumption.
  - inversions H1.
  - lets Hb: (inert_unique_tight_bounds Hgd H H6). subst*.
Qed.

Lemma tight_possible_types_lemma_v : forall G v T,
    inert G ->
    G |-# trm_val v : T ->
    G |-##v v : T.
Proof.
  introv Hgd Hty.
  dependent induction Hty; eauto.
  specialize (IHHty _ Hgd eq_refl).
  apply* tight_possible_types_closure_tight_v.
Qed.