Set Implicit Arguments.

Require Import LibLN.
Require Import Coq.Program.Equality.
Require Import Definitions.
Require Import Weakening.

(* ###################################################################### *)
(* ###################################################################### *)
(** ** Some Lemmas *)

(* ###################################################################### *)
(** *** Lemmas about Record types *)

Lemma open_dec_preserves_label: forall D x i,
  label_of_dec D = label_of_dec (open_rec_dec i x D).
Proof.
  intros. induction D; simpl; reflexivity.
Qed.

Lemma open_record_dec: forall D x,
  record_dec D -> record_dec (open_dec x D).
Proof.
  intros. inversion H; unfold open_dec; simpl; constructor.
Qed.

Lemma open_record_typ: forall T x ls,
  record_typ T ls -> record_typ (open_typ x T) ls.
Proof.
  intros. induction H.
  - unfold open_typ. simpl.
    apply rt_one.
    apply open_record_dec. assumption.
    rewrite <- open_dec_preserves_label. assumption.
  - unfold open_typ. simpl.
    apply rt_cons; try assumption.
    apply open_record_dec. assumption.
    rewrite <- open_dec_preserves_label. assumption.
Qed.

Lemma open_record_type: forall T x,
  record_type T -> record_type (open_typ x T).
Proof.
  intros. destruct H as [ls H]. exists ls. eapply open_record_typ.
  eassumption.
Qed.

(* ###################################################################### *)
(** *** Lemmas about Record has *)

Lemma record_typ_has_label_in: forall T D ls,
  record_typ T ls ->
  record_has T D ->
  label_of_dec D \in ls.
Proof.
  introv Htyp Has. generalize dependent D. induction Htyp; intros.
  - inversion Has. subst. apply in_singleton_self.
  - inversion Has; subst.
    + rewrite in_union. right. apply in_singleton_self.
    + rewrite in_union. left. apply IHHtyp. assumption.
Qed.

Lemma unique_rcd_typ: forall T A T1 T2,
  record_type T ->
  record_has T (dec_typ A T1 T1) ->
  record_has T (dec_typ A T2 T2) ->
  T1 = T2.
Proof.
  introv Htype Has1 Has2.
  generalize dependent T2. generalize dependent T1. generalize dependent A.
  destruct Htype as [ls Htyp]. induction Htyp; intros; inversion Has1; inversion Has2; subst.
  - inversion H3. subst. reflexivity.
  - inversion H5. subst. reflexivity.
  - apply record_typ_has_label_in with (D:=dec_typ A T2 T2) in Htyp.
    simpl in Htyp. simpl in H1. unfold "\notin" in H1. unfold not in H1.
    specialize (H1 Htyp). inversion H1.
    assumption.
  - apply record_typ_has_label_in with (D:=dec_typ A T1 T1) in Htyp.
    simpl in Htyp. simpl in H1. unfold "\notin" in H1. unfold not in H1.
    specialize (H1 Htyp). inversion H1.
    assumption.
  - eapply IHHtyp; eassumption.
Qed.

(* ###################################################################### *)
(** *** Lemmas to upcast to general typing *)

Lemma precise_to_general:
  (forall m1 G t T,
     ty_trm m1 G t T ->
     m1 = ty_precise ->
     ty_trm ty_general G t T) /\
  (forall m1 G S U,
     subtyp m1 G S U ->
     m1 = ty_precise ->
     subtyp ty_general G S U).
Proof.
  apply ts_mutind; intros; subst; eauto.
Qed.

Lemma tight_to_general:
  (forall m1 G t T,
     ty_trm_t m1 G t T ->
     m1 = ty_general ->
     ty_trm ty_general G t T) /\
  (forall m1 G S U,
     subtyp_t m1 G S U ->
     m1 = ty_general ->
     subtyp ty_general G S U) /\
  (forall G p,
     norm_t G p ->
     norm G p).
Proof.
  apply ts_mutind_t; intros; subst; eauto.
  - apply precise_to_general in t; eauto.
  - apply precise_to_general in t; eauto.
  - apply* norm_var.
  - apply* norm_path.
Qed.

(* ###################################################################### *)
(** *** Misc Lemmas *)

Lemma var_typing_implies_avar_f: forall G a T,
  ty_trm ty_general G (trm_path (p_var a)) T ->
  exists x, a = avar_f x.
Proof.
  intros. dependent induction H; try solve [eexists; reflexivity].
  apply* IHty_trm. apply* IHty_trm2. apply* IHty_trm.
Qed.

Lemma val_typing: forall G v T,
  ty_trm ty_general G (trm_val v) T ->
  exists T', ty_trm ty_precise G (trm_val v) T' /\
             subtyp ty_general G T' T.
Proof.
  intros. dependent induction H.
  - exists (typ_all T U). split.
    apply ty_all_intro with (L:=L); eauto. apply subtyp_refl.
  - exists (typ_bnd T). split.
    apply ty_new_intro with (L:=L); eauto. apply subtyp_refl.
  - specialize (IHty_trm v eq_refl eq_refl). destruct IHty_trm as [T' [Hty Hsub]].
    exists T'. split; eauto.
Qed.

Lemma typing_implies_bound: forall m1 G x T,
  ty_trm m1 G (trm_path (p_var (avar_f x)))  T ->
  exists S, binds x S G.
Proof.
  intros. remember (trm_path (p_var (avar_f x))) as t.
  induction H;
    try solve [inversion Heqt];
    try solve [inversion Heqt; eapply IHty_trm; eauto];
    try solve [inversion Heqt; eapply IHty_trm1; eauto].
  - inversion Heqt. subst. exists T. assumption.
Qed.