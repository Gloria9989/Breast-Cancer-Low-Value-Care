Breast cancer low value care definitions and queries using SAS.

/********************************************
Purpose: query 5 kinds of breast cancer low value care in 91~92 outpatient dataset
DATA SETS: Tmp1.Tcdb_breast91.sas7bdat, Tmp1.Tcdb_breast92.sas7bdat, and merged datasets
PROGRAMMER: Run Xiang 
********************************************/

libname Run X.  "H:\BreastCancer";

/* tcdb-91~92 breat cancer dataset*/;
data tcdb91; set Tmp1.Tcdb_breast91;
data tcdb92; set Tmp1.Tcdb_breast92;
data r.tcdb9192;
set  tcdb91  tcdb92;
run;

/*1, whole-breast radiation therapy, in 25 fractions, in 50 years of age and older with early-stage invasive breast cancer*/

/*only patient with breast-conserving surgery, OPTYPE 2 number code*/
data t2; set tcdb9192;
op=substr(OPTYPE,1,2)*1;
proc means/univariate; 
var OP;
run;

/*types of surgery*/
/*19 Local tumor destruction, 
20 Partial mastectomy(less than total mastectomy)
21 Partial mastectomy WITH nipple resection, 22 Lumpectomy or excisional biopsy,
23 Reexcision of the biopsy site for gross or microscopic residual disease,
24 Segmental mastectomy (including wedge resection, quadrantectomy, tylectomy)
30 Subcutaneous mastectomy*/
data r.BCS_1; set r.tcdb9192; /*total smaple size: 1448 */
if substr(OPTYPE,1,2) in ('19','20','21','22','24','30') then operation=1;
else delete;
run;

/*early stage breast cancer, code in 1, 1A,1B1,1C, 2,2A, 2B*/
/*total 1105*/
proc freq data=r.BCS_1; table PSTAGE; 
run;
data r.BCS_2; set r.BCS_1;
if substr(PSTAGE,1,3) in ('1','1A', '1B1', '1C', '2','2A', '2B') then earlyBC=1; 
else delete;
run;

/*define age gp; there are too many 9999*/  
data r.age50; set r.BCS_2;
if idiagy=9999 then delete;
if biry=9999 then delete; 
birthyear=substr(biry,1,4)*1;
treatdate=substr(idiagy,1,4)*1;  /*format as YYYYMMDD*/
age=treatdate-birthyear; 
if age<50 then delete;
run;

/*number of fractionation*/
data r.CTL_1; set  r.age50;
proc means; var RTH_NF; 
run;

/*RTNO, 2 number code*/
proc freq data=r.age50; table RTNO; run;
data r.RT_1; set r.age50;
fraction=substr(RTNO,1,2)*1; /*convert category to number*/
if fraction=99 then delete; /*remain only 270*/
data r.RT_2; set r.RT_1;
if fraction>=25 then RTgp=1;
if fraction<25 then RTgp=2;
proc freq; table RTgp;
run;

/*2, IMRT for whole breast radiation therapy after breast-conserving surgery */
data r.BCS_1; set r.tcdb9192; /*no OPTYPE_O*/
if substr(OPTYPE,1,2) in ('19','20','21','22','24','30') then operation=1;
else delete;
run;

/* whole breast radiation*/
/*if RTH=1 or 2 then RT=1;
if RTL=1 or 2 then RT=1;
else RT=0;
run;*/

/*IMRT EBRT, 3 number code*/
data  r.IMRT; set  r.BCS_1;
if substr(EBRT,1,3) in ('4') then IMRt=1;
else IMRT=0;
run;

data htn3; set r.BCS_1;
by id; 
if first.ID then count=0;
count+1; 
if last.ID;
keep ID count;
run;

/*3, re-excision after Breast-Conserving Surgery*/
/*first excison*/
data r.BCS_1; set r.tcdb9192; /*no OPTYPE_O*/
if substr(OPTYPE,1,2) in ('19','20','21','22','24','30') then operation=1;
else delete;
data  BCS_2;  set  r.BCS_1;
keep ID; 
run; /* keep ID from original dataset*/


/*4, Don't perform axillary lymph node dissection for clinical stages I and II breast cancer 
with clinically negative lymph nodes without Sentinel Lymph Node Biopsy  (SLNB).*/

/* only stages I and II breast cancer */
data r.earlyBC; set r.tcdb9192;
if substr(PSTAGE,1,3) in ('1','1A', '1B1', '1C', '2','2A', '2B') then earlyBC=1;
else earlybc=0;
run;  
proc freq data=r.tcdb9192; table PSTAGE; run;
proc freq data=r.earlyBC; table earlyBC; run;


/*axillary lymph node dissection(ALND)*/
data ALND; set  r.earlyBC; /*distribution of operation*/
proc freq data= ALND; table OPTYPE ; run; 
data ALND2; set r.earlyBC; /*distribution of lymphenode operation*/
proc freq data= r.ALND; table LNSCOPE ; run; 

data r.ALND; set  r.earlyBC; 
if substr(LNSCOPE,1,1) in ('9') then delete;  /* LNSCOPE has 1 code number*/
if substr(LNSCOPE,1,1) in ('3','7','8') then ALND=1; 
else ALND=0; 
proc freq; table ALND;
run;

/*5, Routinely Re-operate on Women with Invasive Breast cancer 
if the Cancer is Close to the Edge of the Excised Lumpectomy Tissue*/
proc freq data= r.tcdb9192; table smargin; run;
data r.REOP_1; set r.tcdb9192;
if substr(smargin,1,1) in ('7','8','9') then delete;  
if substr (smargin,1,1) in ('1','2','3','4','5') then marg=1;
else marg=0;
proc freq; table marg;
run;






