*****************************************************************************
*****************************************************************************
*Author:			[Author Anonymized for Peer Review]
*Topic:				Contact and Labor Market Participation
*Date created:		08/01/2023
*Date modified:		06/24/2025
*****************************************************************************
*****************************************************************************

log using "E:\[Anonymized]\Job Search\LMParticipation_PublicFiles\Log Output\SECTION 1 - Data Cleaning", ///
	text replace

cd "E:\[Anonymized]\Job Search\LMParticipation_PublicFiles\DataPull_PSID"
use "FullData.dta", clear

*GENERATING PARTICIPANT ID 
gen ParticipantID=((ER30001*1000)+ER30002)
format ParticipantID %10.0g
drop ER30001 ER30002


********************************************************************************
********************************************************************************
*******************************  DATA CLEANING  ********************************
********************************************************************************
********************************************************************************
**
**TAS INDICATOR**
**
rename (TAS05 TAS07 TAS09 TAS11 TAS13 TAS15) ///
	   (TAS5 TAS7 TAS9 TAS11 TAS13 TAS15)
	
**
**SEX**
**
rename ER32000 Sex
recode Sex 2=0
label define sx 0"Female" 1"Male"
	label value Sex sx

	/* Respondent gender, pulled from Individual Level Files
		0 = Female
		1 = Male
	*/

**
**MARITAL STATUS**
**
rename (TA050069 TA070069 TA090078 TA110079 TA130078 TA150070) (mar5 mar7 mar9 mar11 mar13 mar15)
rename (TA050072 TA070072 TA090081 TA110082 TA130081 TA150073) (co5 co7 co9 co11 co13 co15)

foreach x in 5 7 9 11 13 15 {
	recode co`x' 0=. 9=. 8=. 5=0
	recode mar`x' 9=.
	}
	
label define relate 1"Single, never married" 2"Married" 3"Cohabitating, not married" 4"Widowed/divorced/separated"
foreach x in 5 7 9 11 13 15 {
	gen RelationshipStatus`x'=.
	replace RelationshipStatus`x'=1 if mar`x'==2
	replace RelationshipStatus`x'=2 if mar`x'==1	
	replace RelationshipStatus`x'=3 if co`x'==1 & mar`x'!=1
	replace RelationshipStatus`x'=4 if mar`x'==3 & RelationshipStatus`x'==. ///
		| mar`x'==4 & RelationshipStatus`x'==. ///
		| mar`x'==5 & RelationshipStatus`x'==.
	label value RelationshipStatus`x' relate
	label var RelationshipStatus`x' "Current relationship status"
	}
	
	/* Current relationship status
		1 = Single, never married
		2 = Married
		3 = Cohabitating, not married (including previous divorced/separated/widowed)
		4 = Widowed/divorced/separated
	*/

**
**RACE/ETHNICITY**
**
recode CHRACE 9=. 5/7=4
	label define race 1"White" 2"Black" 3"Hispanic" 4"Other"
	label value CHRACE race
	label var CHRACE "Race/ethnicity"
	rename CHRACE Race
	
	/* Respondent race, pulled from Childhood Development Supplement
		1 = White
		2 = Black
		3 = Hispanic
		4 = Other
	*/

**
**AGE**
**
rename (ER33804 ER33904 ER34004 ER34104 ER34204 ER34305) (AGE5 AGE7 AGE9 AGE11 AGE13 AGE15)

foreach x in AGE5 AGE7 AGE9 AGE11 AGE13 AGE15 {
	recode `x' 0=.
	label var `x' "Age"
	}
	
	/* Respondent age at wave
		17 - 31 : Actual values
	*/
	
**
**HEALTH**
**
rename (TA050676 TA070647 TA090700 TA110788 TA130808 TA150821) ///
	   (Health5 Health7 Health9 Health11 Health13 Health15)
	   
foreach x in 5 7 9 11 13 15 {
	recode Health`x' 9 = .
	label var Health`x' "Self-reported health level"
	}
	
	/* Health level
		1 = Excellent 
		2 = Very good 
		3 = Good
		4 = Fair
		5 = Poor
	*/


**
**CHILDREN**
**
rename (TA050091 TA070091 TA090100 TA110101 TA130100 TA150092) ///
	   (NumKids5 NumKids7 NumKids9 NumKids11 NumKids13 NumKids15)
	  
label define kids 0"0" 1"1" 2"2" 3"3" 4"4" 5"5" 6"6" 7"7" 8"8" 9"9" 10"10" 11"11" 12"12"
foreach x in 5 7 9 11 13 15 {
	recode NumKids`x' 98=. 99=.
	label value NumKids`x' kids
	label var NumKids`x' "Number of children"
	}
	
	/* Number of children
		0 - 12 : Actual values
	*/
	
	*Creating dichotomous indicator of children
	label define yn 0"No" 1"Yes"
	foreach x in 5 7 9 11 13 15 {
		gen KidsYN`x'=.
		replace KidsYN`x'=0 if NumKids`x'==0
		replace KidsYN`x'=1 if NumKids`x'>=1 & NumKids`x'!=.
		label value KidsYN`x' yn
		label var KidsYN`x' "R has children, dichotomous"
		}
		
	/* Respondent has children, any
		0 = No
		1 = Yes (1 or more)
	*/
	
**
**EDUCATION
**
rename (TA091008 TA111150 TA131241 TA151301) ///
	   (HighestEd9 HighestEd11 HighestEd13 HighestEd15) 
	   *NOTE: Not available for 2005, 2007 waves
	   
label define education 1"Less than high school" 2"High school or GED" 3"Some college, no degree" 4"2-year degree" 5"4-year degree" 6"Graduate or professional degree"
	foreach x in 9 11 13 15 {
		recode HighestEd`x' 99=. 3=2 4/5=3 6/7=4 8/9=5 10/19=6
		label value HighestEd`x' education
		label var HighestEd`x' "Highest education"
		}
		
	*Code 96=Skipped, asked in prior wave
	*Creating a loop to fill codes 96 with prior wave information
	foreach x in 11 13 15 {
		local j = `x'-2
		replace HighestEd`x'=HighestEd`j' if HighestEd`x'==96 & HighestEd`j'!=.
		}
	recode HighestEd11 96=.
	recode HighestEd15 96=.
		*Note: Two participants did not report education status in prior wave,
		*	   but were coded as 96; have to code to missing data
		
	/* Highest education
		1 = Less than high school
		2 = High school or equivalent
		3 = Some college, no degree attained
		4 = 2-year degree
		5 = 4-year degree
		6 = Graduate or profesional degree (including law, medical, masters, PhD, etc.)
	*/
		
rename (TA050573 TA070548 TA090590 TA110671 TA130691 TA150701) ///
	   (GraduatedHS5 GraduatedHS7 GraduatedHS9 GraduatedHS11 GraduatedHS13 GraduatedHS15)

label define highschool 0"No degree" 1"High school degree" 2"GED"
foreach x in 5 7 9 11 13 15 {
	recode GraduatedHS`x' 0=96 3=0 8=. 9=.
	label value GraduatedHS`x' highschool
	label var GraduatedHS`x' "Graduated high school or received GED"
	}
	
	*Code 96=Skipped, asked in prior wave
	*Creating a loop to fill codes 96 with prior wave information
	foreach x in 7 9 11 13 15 {
		local j = `x'-2
		replace GraduatedHS`x'=GraduatedHS`j' if GraduatedHS`x'==96 & GraduatedHS`j'!=.
		label value GraduatedHS`x' highschool
		}
	recode GraduatedHS11 96=.
		*Note: One participant did not report graduation status in prior wave,
		*	   but was coded as 96; have to code to missing data
		
	/* Respondent graduated high school
		0 = No
		1 = Yes, high school degree
		2 = GED or other high school equivalent
	*/

/*rename (TA110689 TA130709 TA150719) ///
	   (GraduatedColg11 GraduatedColg13 GraduatedColg15)
	   *NOTE: Not available for the 2005, 2007, 2009 waves
	   
label define college 1"2-year degree" 2"4-year degree" 3"Graduate or professional degree" 4"Other"
foreach x in 11 13 15 {
	recode GraduatedColg`x' 4/6=3 7=4 8=. 9=. 0=96
	label value GraduatedColg`x' college
	label var GraduatedColg`x' "College degree attained"
	}
	
	*Code 96=Skipped, asked in prior wave
	*Creating a loop to fill codes 96 with prior wave information
	foreach x in 13 15 {
		local j = `x'-2
		replace GraduatedColg`x'=GraduatedColg`j' if GraduatedColg`x'==96 & GraduatedColg`j'!=.
		}
		
	/* College degree attained
		1 = 2-year degree
		2 = 4-year degree
		3 = Graduate or professional degree
		4 = Other, unspecified
	*/

NOTE: Graduated college inconsistent in coding; need to determine where 96 codes
come from before it can be used
	*/
	
**
**ENROLLMENT STATUS
**
rename (TA050946 TA070927 TA090991 TA111133 TA131225 TA151285) ///
	   (EnrollNow5 EnrollNow7 EnrollNow9 EnrollNow11 EnrollNow13 EnrollNow15)
	
foreach x in 5 7 9 11 13 15 {
	recode EnrollNow`x' 1/7=0 9/11=1 99=. 99=.
	label value EnrollNow`x' yn
	label var EnrollNow`x' "Enrolled at interview"
	}

	*Code 96=Skipped, asked in prior wave
	*Creating a loop to fill codes 96 with prior wave information
	foreach x in 7 9 11 13 15 {
		local j = `x'-2
		replace EnrollNow`x'=EnrollNow`j' if EnrollNow`x'==96 & EnrollNow`j'!=.
		}	
		
	*Note: 3 individuals in 2011 wave coded as 96 with no prior information on enrollment
	*	   Must be coded as missing, no other information available
	recode EnrollNow11 96=.
		*"(EnrollNow11: 3 changes made)"
		

/*
**UNEMPLOYMENT COMP
**	
rename (TA050411 TA070385 TA090416 TA110496 TA130516 TA150525) ///
	   (Comp5 Comp7 Comp9 Comp11 Comp13 Comp15)
	   
foreach x in 5 7 9 11 13 15 {
	recode Comp`x' 5=0 8/9=.
	label value Comp`x' yn
	label var Comp`x' "Received unemployment comp"
	}	   

	/* Whether received unemployment comp 
		0 = No
		1 = Year
	*/
*/	
	
**
**DRUG AND ALCOHOL USE
**
rename (TA050715 TA070686 TA090742 TA110832 TA130855 TA150872) ///
	   (Alc_Diagnosis5 Alc_Diagnosis7 Alc_Diagnosis9 Alc_Diagnosis11 Alc_Diagnosis13 Alc_Diagnosis15)
rename (TA050716 TA070687 TA090743 TA110833 TA130856 TA150873) ///
	   (Drug_Diagnosis5 Drug_Diagnosis7 Drug_Diagnosis9 Drug_Diagnosis11 Drug_Diagnosis13 Drug_Diagnosis15)
rename (TA050766 TA070737 TA090796 TA110912 TA130945 TA150967) ///
	   (AlcUse5 AlcUse7 AlcUse9 AlcUse11 AlcUse13 AlcUse15)
	   

label define diag 0"Never diagnosed" 1"Diagnosed"
foreach x in 5 7 9 11 13 15 {
	recode AlcUse`x' 8/9 = . 5 = 0
	label value AlcUse`x' yn
	label var AlcUse`x' "Uses alcohol"
	foreach y in Alc_Diagnosis Drug_Diagnosis {
		recode `y'`x' 8=. 9=.
	label value `y'`x' diag
	label var Alc_Diagnosis`x' "Diagnosed with alcohol use disorder"
	label var Drug_Diagnosis`x' "Diagnosed with substance use disorder, not alcohol - substance not specified"
		}
	}

**
**RISKY BEHAVIOR**
**
rename (TA070836 TA090896 TA050855 TA111027 TA131062 TA151102) ///
	   (Dangerous7 Dangerous9 Dangerous5 Dangerous11 Dangerous13 Dangerous15)
rename (TA050856 TA070837 TA131063 TA151103 TA090897 TA111028) ///
	   (Damaged5 Damaged7 Damaged13 Damaged15 Damaged9 Damaged11)
rename (TA050857 TA070838 TA111029 TA151104 TA090898 TA131064) ///
	   (Fight5 Fight7 Fight11 Fight15 Fight9 Fight13)
rename (TA050858 TA111030 TA070839 TA090899 TA131065 TA151105) ///
	   (DriveDrunk5 DriveDrunk11 DriveDrunk7 DriveDrunk9 DriveDrunk13 DriveDrunk15)
rename (TA050859 TA070840 TA090900 TA131066 TA151106 TA111031) ///
	   (RodeDD5 RodeDD7 RodeDD9 RodeDD13 RodeDD15 RodeDD11)
rename (TA151278 TA070920 TA090984 TA050939 TA111126 TA131218) ///
	   (Risky15 Risky7 Risky9 Risky5 Risky11 Risky13)
	
label define scale 1"1" 2"2" 3"3" 4"4" 5"5" 6"6" 7"7"
foreach x in 5 7 9 11 13 15 {
	foreach y in Dangerous Damaged Fight DriveDrunk RodeDD {
		recode `y'`x' 8=. 9=.
		recode Risky`x' 9=.
		label var Dangerous`x' "How often did something dangerous"
		label var Damaged`x' "How often damaged public property"
		label var Fight`x' "How often got into a physical fight"
		label var DriveDrunk`x' "How often drove when drunk or high"
		label var RodeDD`x' "How often rode with drunk driver"
		label var Risky`x' "Risky behavior scale"
		label value Risky`x' scale
		}
	}
	
	/* Dangerous* Damaged* Fight* DriveDrunk* RodeDD* 
		7-point Likert scale
		1 = "Never"
		7 = "21 or more times"
		
	   Risky*
	    Average of all non-missing responses to above questions
		1 - 7 : Actual values
	*/
	
**
**FINANCIAL RESPONSIBILITIES**
**
rename (TA050065 TA070065 TA090066 TA110067 TA130066 TA150066) ///
	   (WorryMoney5 WorryMoney7 WorryMoney9 WorryMoney11 WorryMoney13 WorryMoney15)
rename (TA050066 TA070066 TA090067 TA110068 TA130067 TA150067) ///
	   (WorryJob5 WorryJob7 WorryJob9 WorryJob11 WorryJob13 WorryJob15)
rename (TA050044 TA070044 TA090045 TA110046 TA130045 TA150045) ///
	   (FIN_Living5 FIN_Living7 FIN_Living9 FIN_Living11 FIN_Living13 FIN_Living15)
rename (TA050045 TA070045 TA090046 TA110047 TA130046 TA150046) ///
	   (FIN_Rent5 FIN_Rent7 FIN_Rent9 FIN_Rent11 FIN_Rent13 FIN_Rent15)
rename (TA050046 TA070046 TA090047 TA110048 TA130047 TA150047) ///
	   (FIN_Bills5 FIN_Bills7 FIN_Bills9 FIN_Bills11 FIN_Bills13 FIN_Bills15)
rename (TA050047 TA070047 TA090048 TA110049 TA130048 TA150048) ///
	   (FIN_Money5 FIN_Money7 FIN_Money9 FIN_Money11 FIN_Money13 FIN_Money15)
rename (TA050931 TA070912 TA090976 TA111118 TA131210 TA151270) ///
	   (FIN_Scale5 FIN_Scale7 FIN_Scale9 FIN_Scale11 FIN_Scale13 FIN_Scale15)
rename (TA050050 TA070050 TA090051 TA110052 TA130051 TA150051) ///
	   (MoneyManage5 MoneyManage7 MoneyManage9 MoneyManage11 MoneyManage13 MoneyManage15)
rename (TA050932 TA070913 TA090977 TA111119 TA131211 TA151271) ///
	   (Worry_Scale5 Worry_Scale7 Worry_Scale9 Worry_Scale11 Worry_Scale13 Worry_Scale15)
rename (TA050067 TA070067 TA090068 TA110069 TA130068 TA150068) ///
	   (DiscgdOften5 DiscgdOften7 DiscgdOften9 DiscgdOften11 DiscgdOften13 DiscgdOften15)

foreach x in 5 7 9 11 13 15 {
	foreach y in MoneyManage WorryMoney WorryJob Worry_Scale DiscgdOften {
		recode `y'`x' 8=. 9=. 
		label var WorryMoney`x' "How often wory about money"
		label var WorryJob`x' "How often worry about future job"
		label var MoneyManage`x' "How good at money management"
		label var DiscgdOften`x' "How often do you feel discouraged about the future"
		label value Worry_Scale`x' scale
		label var Worry_Scale`x' "Mental health scale - worry"
		}
	}

foreach x in 5 7 9 11 13 15 {
	foreach y in Living Rent Bills Money Scale {
		recode FIN_`y'`x' 8=. 9=. 
		recode FIN_Rent`x' 6=.s
		recode FIN_Bills`x' 6=.s
		label var FIN_Living`x' "How Much Responsibility for Earning Own Living"
		label var FIN_Rent`x' "How Much Responsibility for Paying Own Rent"
		label var FIN_Bills`x' "How Much Responsibility for Paying Own Bills"
		label var FIN_Money`x' "How much Responsibility for Managing Own Money"
		label var FIN_Scale`x' "Financial responsibilities scale"
		label value FIN_Scale`x' scale
		}
	}

	/* WorryMoney* WorryJob*  
		7-point Likert scale
		1 = "Never"
		7 = "Daily"
		
	   Worry_Scale*
	    Average of all non-missing responses to above questions (plus "How often feel discouraged about future")
		1 - 7 : Actual values
		
	   FIN_Living* FIN_Rent* FIN_Bills* FIN_Money*
	    5-point Likert scale
		1 = Somebody else does this for me all of the time
		5 = I am completely responsible for this all the time
		.s = Not applicable; no bills to pay
		
	   FIN_Scale*
	    Average of all non-missing responses to above questions
		1 - 5 : Actual values
		
	   MoneyManage*
		7-point Likert scale
		1 = "Not at all well"
		7 = "Extremely well"
	*/
	
**
**SOCIAL WELLBEING**
**
rename (TA050891 TA070872 TA090932 TA111064 TA131100 TA151140) ///
	   (WB_Contribute5 WB_Contribute7 WB_Contribute9 WB_Contribute11 WB_Contribute13 WB_Contribute15) // contribute
rename (TA050892 TA070873 TA090933 TA111065 TA131101 TA151141) ///
	   (WB_Belong5 WB_Belong7 WB_Belong9 WB_Belong11 WB_Belong13 WB_Belong15) // belonging
rename (TA050893 TA070874 TA090934 TA111066 TA131102 TA151142) ///
	   (WB_Better5 WB_Better7 WB_Better9 WB_Better11 WB_Better13 WB_Better15) // better
rename (TA050894 TA070875 TA090935 TA111067 TA131103 TA151143) ///
	   (WB_Good5 WB_Good7 WB_Good9 WB_Good11 WB_Good13 WB_Good15) // good
rename (TA050895 TA070876 TA090936 TA111068 TA131104 TA151144) ///
	   (WB_Sense5 WB_Sense7 WB_Sense9 WB_Sense11 WB_Sense13 WB_Sense15) // sense
rename (TA050936 TA070917 TA090981 TA111123 TA131215 TA151275) ///
	   (WB_Scale5 WB_Scale7 WB_Scale9 WB_Scale11 WB_Scale13 WB_Scale15)
	   
foreach x in 5 7 9 11 13 15 {
	recode WB_Scale`x' 8=. 9=.
	label var WB_Scale`x' "Social wellbeing scale"
	label value WB_Scale`x' scale
	}

foreach x in 5 7 9 11 13 15 {
	foreach y in Contribute Belong Better Good Sense {
		recode WB_`y'`x' 8=. 9=. 
		label var WB_Contribute`x' "Frequency of Feeling Something to Contribute to Society"
		label var WB_Belong`x' "Frequency of Feeling Belonging to the Community"
		label var WB_Better`x' "Frequency of Feeling Society Getting Better"
		label var WB_Good`x' "Frequency of Feeling People Basically Good"
		label var WB_Sense`x' "Frequency of Feeling Way Society Works Makes Sense"
		}
	}

	/* WB_Contribute* WB_Belong* WB_Better* WB_Good* WB_Sense
		6-point Likert scale
		1 = "Never"
		6 = "Every day"
		
	   WB_Scale*
	    Average of all non-missing responses to above questions
		1 - 6 : Actual values
	*/

**
**PERCEIVED DISCRIMINATION**
**
rename (TA050826 TA070807 TA090866 TA110997 TA131032 TA151072) ///
	   (DIS_Courtesy5 DIS_Courtesy7 DIS_Courtesy9 DIS_Courtesy11 DIS_Courtesy13 DIS_Courtesy15) // courtesy
rename (TA050827 TA070808 TA090867 TA110998 TA131033 TA151073) ///
	   (DIS_Service5 DIS_Service7 DIS_Service9 DIS_Service11 DIS_Service13 DIS_Service15) // service
rename (TA050828 TA070809 TA090868 TA110999 TA131034 TA151074) ///
	   (DIS_Stupid5 DIS_Stupid7 DIS_Stupid9 DIS_Stupid11 DIS_Stupid13 DIS_Stupid15) // stupid
rename (TA050829 TA070810 TA090869 TA111000 TA131035 TA151075) ///
	   (DIS_Afraid5 DIS_Afraid7 DIS_Afraid9 DIS_Afraid11 DIS_Afraid13 DIS_Afraid15) // afraid
rename (TA050830 TA070811 TA090870 TA111001 TA131036 TA151076) ///
	   (DIS_Dishonest5 DIS_Dishonest7 DIS_Dishonest9 DIS_Dishonest11 DIS_Dishonest13 DIS_Dishonest15) // dishonest
rename (TA050831 TA070812 TA090871 TA111002 TA131037 TA151077) ///
	   (DIS_Superior5 DIS_Superior7 DIS_Superior9 DIS_Superior11 DIS_Superior13 DIS_Superior15) // superior
rename (TA050832 TA070813 TA090872 TA111003 TA131038 TA151078) ///
	   (DIS_Respect5 DIS_Respect7 DIS_Respect9 DIS_Respect11 DIS_Respect13 DIS_Respect15) // less respect
rename (TA050943 TA070924 TA090988 TA111130 TA131222 TA151282) ///
	   (DIS_Scale5 DIS_Scale7 DIS_Scale9 DIS_Scale11 DIS_Scale13 DIS_Scale15)

foreach x in 5 7 9 11 13 15 {
	foreach y in Courtesy Service Stupid Afraid Dishonest Superior Respect Scale {
		recode DIS_`y'`x' 8=. 9=.
		label var DIS_Respect`x' "How often treated with Less Respect"
		label var DIS_Courtesy`x' "How Often Treated with Less Courtesy"
		label var DIS_Service`x' "How Often Receive Poorer Service"
		label var DIS_Stupid`x' "How Often Others Treat as Stupid"
		label var DIS_Afraid`x' "How Often Others Act Afraid"
		label var DIS_Dishonest`x' "How Often Others Treat as Dishonest"
		label var DIS_Superior`x' "How Often Others Act Superior"
		label var DIS_Scale`x' "Everyday discrimination scale"
		label value DIS_Scale`x' scale
		}
	}

	/* DIS_Courtesy* DIS_Service* DIS_Stupid* DIS_Afraid* DIS_Dishonest* DIS_Superior*
		6-point Likert scale
		1 = "Never"
		6 = "Almost every day"
		
	   DIS_Scale*
	    Average of all non-missing responses to above questions
		1 - 6 : Actual values
	*/
	
**
**FUTURE PERCEPTIONS
**
rename (TA050640 TA070611 TA150785 TA110752 TA130772 TA090664) ///
	   (FUT_Support5 FUT_Support7 FUT_Support15 FUT_Support11 FUT_Support13 FUT_Support9) // support family
rename (TA130773 TA050641 TA070612 TA150786 TA110753 TA090665) ///
	   (FUT_Layoff13 FUT_Layoff5 FUT_Layoff7 FUT_Layoff15 FUT_Layoff11 FUT_Layoff9) // layoff
rename (TA110754 TA130774 TA070613 TA050642 TA090666 TA150787) ///
	   (FUT_Harder11 FUT_Harder13 FUT_Harder7 FUT_Harder5 FUT_Harder9 FUT_Harder15) // life harder parents
rename (TA110764 TA050652 TA090676 TA130784 TA070623 TA150797) ///
	   (FUT_JobLike11 FUT_JobLike5 FUT_JobLike9 FUT_JobLike13 FUT_JobLike7 FUT_JobLike15) // job liked
rename (TA150799 TA130786 TA050654 TA110766 TA090678 TA070625) ///
	   (FUT_Comfort15 FUT_Comfort13 FUT_Comfort5 FUT_Comfort11 FUT_Comfort9 FUT_Comfort7) // comfort

foreach x in 5 7 9 11 13 15 {
	foreach y in Support Layoff Harder JobLike Comfort {
		recode FUT_`y'`x' 8=. 9=.
		label var FUT_Support`x' "How likely to be able to support family"
		label var FUT_Layoff`x' "How likely to be laid off from job"
		label var FUT_Harder`x' "How likely life will be harder than parents''"
		label var FUT_JobLike`x' "How likely to have the job you most lke"
		label var FUT_Comfort`x' "How likely to make enough money to be comfortable"
		}
	}
	
**
**JOB QUALITY AND SATISFACTION**
**
rename (TA050207 TA070225 TA090240 TA110242 TA130241 TA150233) ///
	   (SickDays5 SickDays7 SickDays9 SickDays11 SickDays13 SickDays15)
rename (TA050208 TA070226 TA090241 TA110243 TA130242 TA150234) ///
	   (VacayDays5 VacayDays7 VacayDays9 VacayDays11 VacayDays13 VacayDays15)
rename (TA050205 TA070223 TA090238 TA110240 TA130239 TA150231) ///
	   (InsuranceJob5 InsuranceJob7 InsuranceJob9 InsuranceJob11 InsuranceJob13 InsuranceJob15)
	   *Whether has insurance through job
rename (TA070227 TA090242 TA110244 TA130243 TA150235) ///
	   (HIOffer7 HIOffer9 HIOffer11 HIOffer13 HIOffer15)
	   *Whether job offers health insurance
rename (TA070228 TA090243 TA110245 TA130244 TA150236) ///
	   (HICould7 HICould9 HICould11 HICould13 HICould15)
	   *Whether could get insurance through job
rename (TA050639 TA070610 TA090663 TA110751 TA130771 TA150784) ///
	   (LikelyPayWell5 LikelyPayWell7 LikelyPayWell9 LikelyPayWell11 LikelyPayWell13 LikelyPayWell15)
rename (TA050206 TA070224 TA090239 TA110241 TA130240 TA150232) ///
	   (Retirement5 Retirement7 Retirement9 Retirement11 Retirement13 Retirement15)

foreach x in 5 7 9 11 13 15 {
	foreach y in SickDays VacayDays InsuranceJob Retirement {
		recode `y'`x' 8=. 9=.
		label value `y'`x' yn
		label var SickDays`x' "Whether gets sick days from main job"
		label var VacayDays`x' "Whether gets vacation days from main job"
		label var InsuranceJob`x' "Whether has health insurance from main job"
		label var Retirement`x' "Whether has retirement from main job"
		}
	recode LikelyPayWell`x' 8=. 9=. 0=.s
	label value LikelyPayWell`x' scale
	label var LikelyPayWell`x' "How likely to have a job that pays well"
	}

foreach x in 7 9 11 13 15 {
	recode HIOffer`x' 8=. 9=. 0=. 5=0
		label value HIOffer`x' yn
	recode HICould`x' 8=. 9=. 0=. 5=0
		label value HICould`x' yn
	label var HIOffer`x' "Does job offer health insurance"
	label var HICould`x' "Could R get insurance through job"
	}

foreach x in 7 9 11 13 15 {
	replace HIOffer`x' = 1 if InsuranceJob`x' == 1 
	replace HIOffer`x' = 1 if HICould`x' == 1
	}	
	
foreach x in 7 9 11 13 15 {
	egen Benefits`x' = rowtotal(HIOffer`x' SickDays`x' VacayDays`x')
	}	

foreach x in 7 9 11 13 15 {
	replace Benefits`x' = . if TAS`x' == .
	replace Benefits`x' = . if HIOffer`x' == . & SickDays`x' == . & VacayDays`x'==.
	}	

	/* SickDays*
		0 = Job does not offers sick days
		1 = Job offer sick days
		
	   VacayDays*
		0 = Job does not offers vacation days
		1 = Job offer vacation days
		
	   HIOffer*
		0 = Job does not offer health insurance to employeers
		1 = Job does offer health insurance to employees
		
	   HICould*
		0 = R is not eligible to receive health insurance through job
		1 = R is eligible to receive health insurance through job
		
	   InsuranceJob*
		0 = R does not have insurance through main job
		1 = R has insurance through main job
		
	   Benefits*
	    Variety score
		0 = None
		3 = Sick days, vacation days, insurance
		
	   LikelyPayWell*
		7-point Likert scale
		1 = "Very unlikely"
		7 = "Very likely"	
	*/
	
**
**FORCED SEPARATION FROM WORK
**
rename (TA050223 TA050258 TA050293 TA050328 TA050363) ///
	   (EndJobOne5 EndJobTwo5 EndJobThree5 EndJobFour5 EndJobFive5)
rename (TA070255 TA070275 TA070295 TA070315 TA070335) ///
	   (EndJobOne7 EndJobTwo7 EndJobThree7 EndJobFour7 EndJobFive7)
rename (TA090272 TA090292 TA090312 TA090332 TA090352) ///
	   (EndJobOne9 EndJobTwo9 EndJobThree9 EndJobFour9 EndJobFive9)
rename (TA110262 TA110282 TA110302 TA110322 TA110342) ///
	   (EndJobOne11 EndJobTwo11 EndJobThree11 EndJobFour11 EndJobFive11)
rename (TA130261 TA130281 TA130301 TA130321 TA130341) ///
	   (EndJobOne13 EndJobTwo13 EndJobThree13 EndJobFour13 EndJobFive13)
rename (TA150255 TA150277 TA150299 TA150321 TA150343) ///
	   (EndJobOne15 EndJobTwo15 EndJobThree15 EndJobFour15 EndJobFive15)
	  
foreach x in 5 7 9 11 13 15 {
	gen ForceOut`x' = .
}

foreach x in 5 7 9 11 13 15 {
	foreach y in One Two Three Four Five {
		replace ForceOut`x' = 1 if EndJob`y'`x' == 1 | EndJob`y'`x' == 2 | ///
			EndJob`y'`x' == 6
		replace ForceOut`x' = 0 if ForceOut`x' != 1 & TAS`x' == 1
}
}

	/* ForceOut*
		0 = Did not experience a force out from work
		1 = Experienced a forced separation from work
	*/

**
**EARNINGS
**
rename (TA050954 TA070935 TA090999 TA111141 TA131232 TA151292) ///
	   (EarningsLY5 EarningsLY7 EarningsLY9 EarningsLY11 EarningsLY13 EarningsLY15)
rename (TA070936 TA091000 TA111142 TA131233 TA151293) ///
	   (EarningsBefore7 EarningsBefore9 EarningsBefore11 EarningsBefore13 EarningsBefore15)
	   *NOTE: No earnings year before last for 2005
	   
foreach x in 7 9 11 13 15 {
	foreach y in EarningsLY EarningsBefore {
		recode `y'`x' 9999999=. 0=.n
		}
	recode EarningsLY5 9999999=. 0=.n
	*No EarningsBefore for 2005
	label var EarningsLY`x' "Earnings last year - excluding 0 values"
		label var EarningsLY5 "Earnings last year - excluding 0 values"
	label var EarningsBefore`x' "Earnings year before last - excluding 0 values"
	}
	*NOTE: "don't know" and "refused" coded as missing by PSID

	/* EarningsLY* EarningsBefore*
		1 - 9,999,997 : Actual value
		.n = no labor earnings
	*/
	
**
**OCCUPATION CODES
**
rename (TA050189 TA070207 TA090222 TA110223 TA130222 TA150214) ///
	   (OCC5 OCC7 OCC9 OCC11 OCC13 OCC15)
	   
*	Recorded in later section

	
**
**UNEMPLOYMENT COMP
**
rename (TA050411 TA070385 TA090416 TA110496 TA130516 TA150525) ///
	   (UnemploymentComp5 UnemploymentComp7 UnemploymentComp9 UnemploymentComp11 UnemploymentComp13 UnemploymentComp15)
	   
foreach x in 5 7 9 11 13 15 {
	foreach y in UnemploymentComp {
		recode `y'`x' 8=. 9=. 5=0
		label value `y'`x' yn
		label var UnemploymentComp`x' "Received unemployment comp last year"
		}
	}

	/* UnemploymentComp*
		0 = R did not receive unemployment comp last year
		1 = R received unemployment comp last year
	*/
	
**
**ARREST
**
**Ever arrested
gen ArrestEver5 = TA050860
	recode ArrestEver5 1 = 0 2/3 = 1 8 = . 9 = .
		
gen ArrestEver7 = TA070841
	recode ArrestEver7 1 = 0 2/3 = 1 8 = . 9 = .
	replace ArrestEver7 = 1 if ArrestEver5 == 1
		
gen ArrestEver9 = TA090901
	recode ArrestEver9 1 = 0 2/3 = 1 8 = . 9 = .
	replace ArrestEver9 = 1 if ArrestEver7 == 1	
		
gen ArrestEver11 = TA111032
	recode ArrestEver11 1 = 0 2/3 = 1 8 = . 9 = .
	replace ArrestEver11 = 1 if ArrestEver9 == 1		
		
gen ArrestEver13 = TA131067
	recode ArrestEver13 1 = 0 2/3 = 1 8 = . 9 = .
	replace ArrestEver13 = 1 if ArrestEver11 == 1	
		
gen ArrestEver15 = TA151107
	recode ArrestEver15 1 = 0 2/3 = 1 8 = . 9 = .
	replace ArrestEver15 = 1 if ArrestEver13 == 1
	
foreach x in 5 7 9 11 13 15 {
	replace ArrestEver`x' = . if TAS`x'!=1
	}
	

*Age at first/last arrest
rename (TA050862 TA070843 TA090903 TA111034 TA131069 TA151109) ///
	   (AgeFirstArrest5 AgeFirstArrest7 AgeFirstArrest9 AgeFirstArrest11 AgeFirstArrest13 AgeFirstArrest15)
	   
rename (TA050861 TA070842 TA090902 TA111033 TA131068 TA151108) ///
	   (AgeOnlyArrest5 AgeOnlyArrest7 AgeOnlyArrest9 AgeOnlyArrest11 AgeOnlyArrest13 AgeOnlyArrest15)
	   
rename (TA050864 TA070845 TA090905 TA111036 TA131071 TA151111) ///
	   (AgeLastArrest5 AgeLastArrest7 AgeLastArrest9 AgeLastArrest11 AgeLastArrest13 AgeLastArrest15)
	   
foreach x in 5 7 9 11 13 15 {
	recode AgeFirstArrest`x' 0=. 98=. 99=.
	recode AgeOnlyArrest`x' 0=. 98=. 99=.
	recode AgeLastArrest`x' 0=. 98=. 99=.
	replace AgeFirstArrest`x'=AgeOnlyArrest`x' if AgeFirstArrest`x'==. & AgeOnlyArrest`x'!=.
	replace AgeLastArrest`x'=AgeOnlyArrest`x' if AgeLastArrest`x'==. & AgeOnlyArrest`x'!=.
	label var AgeFirstArrest`x' "Age at first arrest"
	label var AgeLastArrest`x' "Age at last arrest"
	}
	
	
*Type of offense
rename (TA050863 TA070844 TA090904 TA111035 TA131070 TA151110) ///
	   (OffFirstArrest5 OffFirstArrest7 OffFirstArrest9 OffFirstArrest11 OffFirstArrest13 OffFirstArrest15)
	   
rename (TA131072 TA070846 TA090906 TA151112 TA111037 TA050865) ///
	   (OffLastArrest5 OffLastArrest7 OffLastArrest9 OffLastArrest11 OffLastArrest13 OffLastArrest15)
	   
foreach x in 5 7 9 11 13 15 {
	recode OffFirstArrest`x' 0=. 8=. 9=.
	recode OffLastArrest`x' 0=. 8=. 9=.
	replace OffLastArrest`x'=OffFirstArrest`x' if OffLastArrest`x'==. & OffFirstArrest`x'!=.
	label var OffFirstArrest`x' "Offense type of first arrest"
	label var OffLastArrest`x' "Offense type of last arrest"
	}

	
	/* ArrestEver*
		0 = Never arrested
		1 = Previously arrested
		
	   AgeFirstArrest*
	   AgeLastArrest*
		1 - 30 : Actual values
		
	   OffFirstArrest*
	   OffLastArrest*
	    1 = Severe violent offense
		2 = Other severe offense
		3 = Non-severe offense 
		4 = Traffic violation 
		7 = Other offense
	*/
	
**
**PROBATION
**
gen ProbationEver5 = TA050866
	recode ProbationEver5 1 = 0 2/3 = 1 8 = . 9 = .
   
gen ProbationEver7 = TA070847
	recode ProbationEver7 1 = 0 2/3 = 1 8 = . 9 = .
	replace ProbationEver7 = 1 if ProbationEver5 == 1
 
gen ProbationEver9 = TA090907
	recode ProbationEver9 1 = 0 2/3 = 1 8 = . 9 = .
	replace ProbationEver9 = 1 if ProbationEver7 == 1
		
gen ProbationEver11 = TA111038
	recode ProbationEver11 1 = 0 2/3 = 1 8 = . 9 = .
	replace ProbationEver11 = 1 if ProbationEver9 == 1
		
gen ProbationEver13 = TA131073
	recode ProbationEver13 1 = 0 2/3 = 1 8 = . 9 = .
	replace ProbationEver13 = 1 if ProbationEver11 == 1

gen ProbationEver15 = TA151113
	recode ProbationEver15 1 = 0 2/3 = 1 8 = . 9 = . 
	replace ProbationEver15 = 1 if ProbationEver13 == 1 
	
foreach x in 5 7 9 11 13 15 {
	replace ProbationEver`x' = . if TAS`x'!=1
	}
	
	
*Age at first/last probation
rename (TA050868 TA070849 TA090909 TA111040 TA131075 TA151115) ///
	   (AgeFirstProbation5 AgeFirstProbation7 AgeFirstProbation9 AgeFirstProbation11 AgeFirstProbation13 AgeFirstProbation15)
	   
rename (TA050867 TA070848 TA090908 TA111039 TA131074 TA151114) ///
	   (AgeOnlyProbation5 AgeOnlyProbation7 AgeOnlyProbation9 AgeOnlyProbation11 AgeOnlyProbation13 AgeOnlyProbation15)
	   
rename (TA050870 TA070851 TA090911 TA111042 TA131077 TA151117) ///
	   (AgeLastProbation5 AgeLastProbation7 AgeLastProbation9 AgeLastProbation11 AgeLastProbation13 AgeLastProbation15)
	   
foreach x in 5 7 9 11 13 15 {
	recode AgeFirstProbation`x' 0=. 98=. 99=.
	recode AgeOnlyProbation`x' 0=. 98=. 99=.
	recode AgeLastProbation`x' 0=. 98=. 99=.
	replace AgeFirstProbation`x'=AgeOnlyProbation`x' if AgeFirstProbation`x'==. & AgeOnlyProbation`x'!=.
	replace AgeLastProbation`x'=AgeOnlyProbation`x' if AgeLastProbation`x'==. & AgeOnlyProbation`x'!=.
	label var AgeFirstProbation`x' "Age at first probation"
	label var AgeLastProbation`x' "Age at last probation"
	}
	
	
*Type of offense
rename (TA050869 TA070850 TA090910 TA111041 TA131076 TA151116) ///
	   (OffFirstProbation5 OffFirstProbation7 OffFirstProbation9 OffFirstProbation11 OffFirstProbation13 OffFirstProbation15)
	   
rename (TA050871 TA070852 TA090912 TA111043 TA131078 TA151118) ///
	   (OffLastProbation5 OffLastProbation7 OffLastProbation9 OffLastProbation11 OffLastProbation13 OffLastProbation15)
	   
foreach x in 5 7 9 11 13 15 {
	recode OffFirstProbation`x' 0=. 8=. 9=.
	recode OffLastProbation`x' 0=. 8=. 9=.
	replace OffLastProbation`x'=OffFirstProbation`x' if OffLastProbation`x'==. & OffFirstProbation`x'!=.
	label var OffFirstProbation`x' "Offense type of first probation"
	label var OffLastProbation`x' "Offense type of last probation"
	}

	
	/* ProbationEver*
		0 = Never probationed
		1 = Previously probationed
		
	   AgeFirstProbation*
	   AgeLastProbation*
		1 - 30 : Actual values
		
	   OffFirstProbation*
	   OffLastProbation*
	    1 = Severe violent offense
		2 = Other severe offense
		3 = Non-severe offense 
		4 = Traffic violation 
		7 = Other offense
	*/

	
	/* ProbationEver*
		0 = Never on probation
		1 = Previously on probation
		
	   AgeFirstProbation*
	   AgeLastProbation*
		1 - 30 : Actual values
	*/
	
	
**
**JAIL
**
gen JailEver5 = TA050872
	recode JailEver5 1 = 0 2/3 = 1 8 = . 9 = .
		
gen JailEver7 = TA070853
	recode JailEver7 1 = 0 2/3 = 1 8 = . 9 = .
	replace JailEver7 = 1 if JailEver5 == 1
	
gen JailEver9 = TA090913
	recode JailEver9 1 = 0 2/3 = 1 8 = . 9 = .
	replace JailEver9 = 1 if JailEver7 == 1

gen JailEver11 = TA111044
	recode JailEver11 1 = 0 2/3 = 1 8 = . 9 = .
	replace JailEver11 = 1 if JailEver9 == 1
		
gen JailEver13 = TA131079
	recode JailEver13 1 = 0 2/3 = 1 8 = . 9 = .
	replace JailEver13 = 1 if JailEver11 == 1
		
gen JailEver15 = TA151119
	recode JailEver15 1 = 0 2/3 = 1 8 = . 9 = .
	replace JailEver15 = 1 if JailEver13 == 1
	
foreach x in 5 7 9 11 13 15 {
	replace JailEver`x' = . if TAS`x'!=1
	}
	
	
*Age at first/last jail
rename (TA050874 TA070855 TA090915 TA111046 TA131081 TA151121) ///
	   (AgeFirstJail5 AgeFirstJail7 AgeFirstJail9 AgeFirstJail11 AgeFirstJail13 AgeFirstJail15)
	   
rename (TA050873 TA070854 TA090914 TA111045 TA131080 TA151120) ///
	   (AgeOnlyJail5 AgeOnlyJail7 AgeOnlyJail9 AgeOnlyJail11 AgeOnlyJail13 AgeOnlyJail15)
	   
rename (TA050876 TA070857 TA090917 TA111048 TA131083 TA151123) ///
	   (AgeLastJail5 AgeLastJail7 AgeLastJail9 AgeLastJail11 AgeLastJail13 AgeLastJail15)
	   
foreach x in 5 7 9 11 13 15 {
	recode AgeFirstJail`x' 0=. 98=. 99=.
	recode AgeOnlyJail`x' 0=. 98=. 99=.
	recode AgeLastJail`x' 0=. 98=. 99=.
	replace AgeFirstJail`x'=AgeOnlyJail`x' if AgeFirstJail`x'==. & AgeOnlyJail`x'!=.
	replace AgeLastJail`x'=AgeOnlyJail`x' if AgeLastJail`x'==. & AgeOnlyJail`x'!=.
	label var AgeFirstJail`x' "Age at first jail"
	label var AgeFirstJail`x' "Age at last jail"
	}
	
	
*Type of offense
rename (TA050875 TA070856 TA090916 TA111047 TA131082 TA151122) ///
	   (OffFirstJail5 OffFirstJail7 OffFirstJail9 OffFirstJail11 OffFirstJail13 OffFirstJail15)
	   
rename (TA050877 TA070858 TA090918 TA111049 TA131084 TA151124) ///
	   (OffLastJail5 OffLastJail7 OffLastJail9 OffLastJail11 OffLastJail13 OffLastJail15)
	   
foreach x in 5 7 9 11 13 15 {
	recode OffFirstJail`x' 0=. 8=. 9=.
	recode OffLastJail`x' 0=. 8=. 9=.
	replace OffLastJail`x'=OffFirstJail`x' if OffLastJail`x'==. & OffFirstJail`x'!=.
	label var OffFirstJail`x' "Offense type of first jail"
	label var OffLastJail`x' "Offense type of last jail"
	}

	
	/* JailEver*
		0 = Never jailed
		1 = Previously jailed
		
	   AgeFirstJail*
	   AgeLastJail*
		1 - 30 : Actual values
		
	   OffFirstJail*
	   OffLastJail*
	    1 = Severe violent offense
		2 = Other severe offense
		3 = Non-severe offense 
		4 = Traffic violation 
		7 = Other offense
	*/
	
	
**
**TYPE OF OFFENSE SUPPLEMENT
**

global lasto OffLastArrest11 OffLastArrest13 OffLastArrest15 OffLastArrest5 ///
	OffLastArrest7 OffLastArrest9 OffLastJail11 OffLastJail13 OffLastJail15 ///
	OffLastJail5 OffLastJail7 OffLastJail9 OffLastProbation11 OffLastProbation13 ///
	OffLastProbation15 OffLastProbation5 OffLastProbation7 OffLastProbation9

foreach x in $lasto {
	clonevar s_`x' = `x'
	replace s_`x' = 0 if s_`x' == .	
	}

foreach x in 5 7 9 11 13 15 {
	replace s_OffLastArrest`x' = . if TAS`x' != 1
	replace s_OffLastProbation`x' = . if TAS`x' != 1
	replace s_OffLastJail`x' = . if TAS`x' != 1
	}

	
	
cd "E:\[Anonymized]\Job Search\LMParticipation_PublicFiles\DataPull_PSID\Cleaned"
save "CleanedCov.dta", replace

log close
cls



log using "E:\[Anonymized]\Job Search\LMParticipation_PublicFiles\Log Output\SECTION 2 - Market States", ///
	text replace


**
**EMPLOYMENT
**
keep TA050185 TA070203 TA090218 TA110219 TA130218 TA150210 TA050225 TA070256 TA090273 ///
	TA110263 TA130262 TA150256 TA050260 TA070276 TA090293 TA110283 TA130282 TA150278 ///
	TA050295 TA070296 TA090313 TA110303 TA130302 TA150300 TA050330 TA070316 TA090333 ///
	TA110323 TA130322 TA150322 TA050186 TA070204 TA090219 TA110220 TA130219 TA150211 ///
	TA050226 TA070257 TA090274 TA110264 TA130263 TA150257 TA050261 TA070277 TA090294 ///
	TA110284 TA130283 TA150279 TA050296 TA070297 TA090314 TA110304 TA130303 TA150301 ///
	TA050331 TA070317 TA090334 TA110324 TA130323 TA150323 TA050187 TA070205 TA090220 ///
	TA110221 TA130220 TA150212 TA050227 TA070258 TA090275 TA110265 TA130264 TA150258 ///
	TA050262 TA070278 TA090295 TA110285 TA130284 TA150280 TA050297 TA070298 TA090315 ///
	TA110305 TA130304 TA150302 TA050332 TA070318 TA090335 TA110325 TA130324 TA150324 ///
	TA050188 TA070206 TA090221 TA110222 TA130221 TA150213 TA050228 TA070259 TA090276 ///
	TA110266 TA130265 TA150259 TA050263 TA070279 TA090296 TA110286 TA130285 TA150281 ///
	TA050298 TA070299 TA090316 TA110306 TA130305 TA150303 TA050333 TA070319 TA090336 ///
	TA110326 TA130325 TA150325 ParticipantID
	
/* Naming scheme:
	Stems: BeginMo BeginYr EndMo EndYr
	Job Number: One Two Three Four Five
	wave of Collection: 5 7 9 11 13 15	*/ 

rename (TA050185 TA070203 TA090218 TA110219 TA130218 TA150210) (BeginMoOne5 BeginMoOne7 BeginMoOne9 BeginMoOne11 BeginMoOne13 BeginMoOne15)
rename (TA050225 TA070256 TA090273 TA110263 TA130262 TA150256) (BeginMoTwo5 BeginMoTwo7 BeginMoTwo9 BeginMoTwo11 BeginMoTwo13 BeginMoTwo15)
rename (TA050260 TA070276 TA090293 TA110283 TA130282 TA150278) (BeginMoThree5 BeginMoThree7 BeginMoThree9 BeginMoThree11 BeginMoThree13 BeginMoThree15)
rename (TA050295 TA070296 TA090313 TA110303 TA130302 TA150300) (BeginMoFour5 BeginMoFour7 BeginMoFour9 BeginMoFour11 BeginMoFour13 BeginMoFour15)
rename (TA050330 TA070316 TA090333 TA110323 TA130322 TA150322) (BeginMoFive5 BeginMoFive7 BeginMoFive9 BeginMoFive11 BeginMoFive13 BeginMoFive15)
rename (TA050186 TA070204 TA090219 TA110220 TA130219 TA150211) (BeginYrOne5 BeginYrOne7 BeginYrOne9 BeginYrOne11 BeginYrOne13 BeginYrOne15)
rename (TA050226 TA070257 TA090274 TA110264 TA130263 TA150257) (BeginYrTwo5 BeginYrTwo7 BeginYrTwo9 BeginYrTwo11 BeginYrTwo13 BeginYrTwo15)
rename (TA050261 TA070277 TA090294 TA110284 TA130283 TA150279) (BeginYrThree5 BeginYrThree7 BeginYrThree9 BeginYrThree11 BeginYrThree13 BeginYrThree15)
rename (TA050296 TA070297 TA090314 TA110304 TA130303 TA150301) (BeginYrFour5 BeginYrFour7 BeginYrFour9 BeginYrFour11 BeginYrFour13 BeginYrFour15)
rename (TA050331 TA070317 TA090334 TA110324 TA130323 TA150323) (BeginYrFive5 BeginYrFive7 BeginYrFive9 BeginYrFive11 BeginYrFive13 BeginYrFive15)

rename (TA050187 TA070205 TA090220 TA110221 TA130220 TA150212) (EndMoOne5 EndMoOne7 EndMoOne9 EndMoOne11 EndMoOne13 EndMoOne15)
rename (TA050227 TA070258 TA090275 TA110265 TA130264 TA150258) (EndMoTwo5 EndMoTwo7 EndMoTwo9 EndMoTwo11 EndMoTwo13 EndMoTwo15)
rename (TA050262 TA070278 TA090295 TA110285 TA130284 TA150280) (EndMoThree5 EndMoThree7 EndMoThree9 EndMoThree11 EndMoThree13 EndMoThree15)
rename (TA050297 TA070298 TA090315 TA110305 TA130304 TA150302) (EndMoFour5 EndMoFour7 EndMoFour9 EndMoFour11 EndMoFour13 EndMoFour15)
rename (TA050332 TA070318 TA090335 TA110325 TA130324 TA150324) (EndMoFive5 EndMoFive7 EndMoFive9 EndMoFive11 EndMoFive13 EndMoFive15)
rename (TA050188 TA070206 TA090221 TA110222 TA130221 TA150213) (EndYrOne5 EndYrOne7 EndYrOne9 EndYrOne11 EndYrOne13 EndYrOne15)
rename (TA050228 TA070259 TA090276 TA110266 TA130265 TA150259) (EndYrTwo5 EndYrTwo7 EndYrTwo9 EndYrTwo11 EndYrTwo13 EndYrTwo15)
rename (TA050263 TA070279 TA090296 TA110286 TA130285 TA150281) (EndYrThree5 EndYrThree7 EndYrThree9 EndYrThree11 EndYrThree13 EndYrThree15)
rename (TA050298 TA070299 TA090316 TA110306 TA130305 TA150303) (EndYrFour5 EndYrFour7 EndYrFour9 EndYrFour11 EndYrFour13 EndYrFour15)
rename (TA050333 TA070319 TA090336 TA110326 TA130325 TA150325) (EndYrFive5 EndYrFive7 EndYrFive9 EndYrFive11 EndYrFive13 EndYrFive15)


*CLEANING VARIABLES
*	0 = not employed during this time or still working for employer
*	9998 = don't know
*	9999 = refuse
*	Recoding seasonal months to months that season begins
foreach x in One Two Three Four Five {
	foreach y in 5 7 9 11 13 15 {
		recode BeginMo`x'`y' 0=. 98=. 99=. 21=12 22=3 23=6 24=9
		recode EndMo`x'`y' 0=. 98=. 99=. 21=12 22=3 23=6 24=9
		recode BeginYr`x'`y' 0=. 9998=. 9999=. 
		recode EndYr`x'`y' 0=. 9998=. 9999=.
		}
	}
	

*RESHAPING LONG
reshape long BeginMoOne BeginMoTwo BeginMoThree BeginMoFour BeginMoFive BeginYrOne ///
	BeginYrTwo BeginYrThree BeginYrFour BeginYrFive EndMoOne EndMoTwo EndMoThree ///
	EndMoFour EndMoFive EndYrOne EndYrTwo EndYrThree EndYrFour EndYrFive, i(ParticipantID)
global startend BeginMoOne BeginYrOne EndMoOne EndYrOne BeginMoTwo BeginYrTwo EndMoTwo ///
	EndYrTwo BeginMoThree BeginYrThree EndMoThree EndYrThree BeginMoFour BeginYrFour ///
	EndMoFour EndYrFour BeginMoFive BeginYrFive EndMoFive EndYrFive
format $startend %9.0g


*GENERATING 12-MONTH INTERVALS TO FILL WITH JOB START/STOP DATES
*	Generated for all five jobs
*	12-month intervals generated for two-year periods (24 months total)
foreach x in JobOne JobTwo JobThree JobFour JobFive {
	foreach y in 1 2 3 4 5 6 7 8 9 10 11 12 {
		gen `x'`y'_1Yr=. // At one year recall
		gen `x'`y'_2Yr=. // At two year recall
		gen `x'`y'_CYr=. // At current year (wave of data collection)
		}
	}
	

*2005 2 YEAR EMPLOYMENT DATA

*TWO YEAR				ONE YEAR
*------------			--------------
*JAN 03		1			JAN 04		1
*FEB 03		2			FEB 04		2
*MAR 03		3			MAR 04		3
*APR 03		4			APR 04		4
*MAY 03		5			MAY 04		5
*JUN 03		6			JUN 04		6
*JUL 03		7			JUL 04		7
*AUG 03		8			AUG 04		8
*SEP 03		9			SEP 04		9
*OCT 03		10			OCT 04		10
*NOV 03		11			NOV 04		11
*DEC 03		12			DEC 04		12

*Filling with 1 to indicate the start of a job or the continuation of a job
*from a previous year.
*Filling with 2 to indicate the end of a job.
foreach x in 1 2 3 4 5 6 7 8 9 10 11 12 {
	*Job one
	replace JobOne`x'_2Yr=1 if BeginYrOne==2003 & BeginMoOne==`x' & _j==5 // Job starts at x month in 2003
	replace JobOne`x'_1Yr=1 if BeginYrOne==2004 & BeginMoOne==`x' & _j==5 // Job starts at x month in 2004
	replace JobOne`x'_CYr=1 if BeginYrOne==2005 & BeginMoOne==`x' & _j==5 // Job starts at x month in 2005
	replace JobOne1_2Yr=1 if BeginYrOne<2003 & EndYrOne>=2003 & BeginYrOne!=0 & _j==5 // Job started before 2003; filling Jan 2003 to indicate
	replace JobOne1_1Yr=1 if BeginYrOne<2004 & EndYrOne>=2004 & BeginYrOne!=0 & _j==5  // Job started before 2004; filling Jan 2004 to indicate
	replace JobOne1_CYr=1 if BeginYrOne<2005 & EndYrOne>=2005 & BeginYrOne!=0 & _j==5 // Job started before 2005; filling Jan 2005 to indicate
	replace JobOne`x'_2Yr=2 if EndYrOne==2003 & EndMoOne==`x' & _j==5 // Job ended at x month in 2003
	replace JobOne`x'_1Yr=2 if EndYrOne==2004 & EndMoOne==`x' & _j==5 // Job ended at x month in 2004
	replace JobOne`x'_CYr=2 if EndYrOne==2005 & EndMoOne==`x' & _j==5 // Job ended at x month in 2005
	
	*Job two
	replace JobTwo`x'_2Yr=1 if BeginYrTwo==2003 & BeginMoTwo==`x' & _j==5 // Job starts at x month in 2003
	replace JobTwo`x'_1Yr=1 if BeginYrTwo==2004 & BeginMoTwo==`x' & _j==5 // Job starts at x month in 2004
	replace JobTwo`x'_CYr=1 if BeginYrTwo==2005 & BeginMoTwo==`x' & _j==5 // Job starts at x month in 2005
	replace JobTwo1_2Yr=1 if BeginYrTwo<2003 & EndYrTwo>=2003 & BeginYrTwo!=0 & _j==5 // Job started before 2003; filling Jan 2003 to indicate
	replace JobTwo1_1Yr=1 if BeginYrTwo<2004 & EndYrTwo>=2004 & BeginYrTwo!=0 & _j==5  // Job started before 2004; filling Jan 2004 to indicate
	replace JobTwo1_CYr=1 if BeginYrTwo<2005 & EndYrTwo>=2005 & BeginYrTwo!=0 & _j==5 // Job started before 2005; filling Jan 2005 to indicate
	replace JobTwo`x'_2Yr=2 if EndYrTwo==2003 & EndMoTwo==`x' & _j==5 // Job ended at x month in 2003
	replace JobTwo`x'_1Yr=2 if EndYrTwo==2004 & EndMoTwo==`x' & _j==5 // Job ended at x month in 2004
	replace JobTwo`x'_CYr=2 if EndYrTwo==2005 & EndMoTwo==`x' & _j==5 // Job ended at x month in 2005
	
	*Job three
	replace JobThree`x'_2Yr=1 if BeginYrThree==2003 & BeginMoThree==`x' & _j==5 // Job starts at x month in 2003
	replace JobThree`x'_1Yr=1 if BeginYrThree==2004 & BeginMoThree==`x' & _j==5 // Job starts at x month in 2004
	replace JobThree`x'_CYr=1 if BeginYrThree==2005 & BeginMoThree==`x' & _j==5 // Job starts at x month in 2005
	replace JobThree1_2Yr=1 if BeginYrThree<2003 & EndYrThree>=2003 & BeginYrThree!=0 & _j==5 // Job started before 2003; filling Jan 2003 to indicate
	replace JobThree1_1Yr=1 if BeginYrThree<2004 & EndYrThree>=2004 & BeginYrThree!=0 & _j==5  // Job started before 2004; filling Jan 2004 to indicate
	replace JobThree1_CYr=1 if BeginYrThree<2005 & EndYrThree>=2005 & BeginYrThree!=0 & _j==5 // Job started before 2005; filling Jan 2005 to indicate
	replace JobThree`x'_2Yr=2 if EndYrThree==2003 & EndMoThree==`x' & _j==5 // Job ended at x month in 2003
	replace JobThree`x'_1Yr=2 if EndYrThree==2004 & EndMoThree==`x' & _j==5 // Job ended at x month in 2004
	replace JobThree`x'_CYr=2 if EndYrThree==2005 & EndMoThree==`x' & _j==5 // Job ended at x month in 2005
	
	*Job four
	replace JobFour`x'_2Yr=1 if BeginYrFour==2003 & BeginMoFour==`x' & _j==5 // Job starts at x month in 2003
	replace JobFour`x'_1Yr=1 if BeginYrFour==2004 & BeginMoFour==`x' & _j==5 // Job starts at x month in 2004
	replace JobFour`x'_CYr=1 if BeginYrFour==2005 & BeginMoFour==`x' & _j==5 // Job starts at x month in 2005
	replace JobFour1_2Yr=1 if BeginYrFour<2003 & EndYrFour>=2003 & BeginYrFour!=0 & _j==5 // Job started before 2003; filling Jan 2003 to indicate
	replace JobFour1_1Yr=1 if BeginYrFour<2004 & EndYrFour>=2004 & BeginYrFour!=0 & _j==5  // Job started before 2004; filling Jan 2004 to indicate
	replace JobFour1_CYr=1 if BeginYrFour<2005 & EndYrFour>=2005 & BeginYrFour!=0 & _j==5 // Job started before 2005; filling Jan 2005 to indicate
	replace JobFour`x'_2Yr=2 if EndYrFour==2003 & EndMoFour==`x' & _j==5 // Job ended at x month in 2003
	replace JobFour`x'_1Yr=2 if EndYrFour==2004 & EndMoFour==`x' & _j==5 // Job ended at x month in 2004
	replace JobFour`x'_CYr=2 if EndYrFour==2005 & EndMoFour==`x' & _j==5 // Job ended at x month in 2005
	
	*Job five
	replace JobFive`x'_2Yr=1 if BeginYrFive==2003 & BeginMoFive==`x' & _j==5 // Job starts at x month in 2003
	replace JobFive`x'_1Yr=1 if BeginYrFive==2004 & BeginMoFive==`x' & _j==5 // Job starts at x month in 2004
	replace JobFive`x'_CYr=1 if BeginYrFive==2005 & BeginMoFive==`x' & _j==5 // Job starts at x month in 2005
	replace JobFive1_2Yr=1 if BeginYrFive<2003 & EndYrFive>=2003 & BeginYrFive!=0 & _j==5 // Job started before 2003; filling Jan 2003 to indicate
	replace JobFive1_1Yr=1 if BeginYrFive<2004 & EndYrFive>=2004 & BeginYrFive!=0 & _j==5  // Job started before 2004; filling Jan 2004 to indicate
	replace JobFive1_CYr=1 if BeginYrFive<2005 & EndYrFive>=2005 & BeginYrFive!=0 & _j==5 // Job started before 2005; filling Jan 2005 to indicate
	replace JobFive`x'_2Yr=2 if EndYrFive==2003 & EndMoFive==`x' & _j==5 // Job ended at x month in 2003
	replace JobFive`x'_1Yr=2 if EndYrFive==2004 & EndMoFive==`x' & _j==5 // Job ended at x month in 2004
	replace JobFive`x'_CYr=2 if EndYrFive==2005 & EndMoFive==`x' & _j==5 // Job ended at x month in 2005
	}


*2007 2 YEAR EMPLOYMENT DATA

*TWO YEAR				ONE YEAR
*------------			--------------
*JAN 05		1			JAN 06		13
*FEB 05		2			FEB 06		14
*MAR 05		3			MAR 06		15
*APR 05		4			APR 06		16
*MAY 05		5			MAY 06		17
*JUN 05		6			JUN 06		18
*JUL 05		7			JUL 06		19
*AUG 05		8			AUG 06		20
*SEP 05		9			SEP 06		21
*OCT 05		10			OCT 06		22
*NOV 05		11			NOV 06		23
*DEC 05		12			DEC 06		24

foreach x in 1 2 3 4 5 6 7 8 9 10 11 12 {
	*Job one
	replace JobOne`x'_2Yr=1 if BeginYrOne==2005 & BeginMoOne==`x' & _j==7 // Job starts at x month in 2005
	replace JobOne`x'_1Yr=1 if BeginYrOne==2006 & BeginMoOne==`x' & _j==7 // Job starts at x month in 2006
	replace JobOne`x'_CYr=1 if BeginYrOne==2007 & BeginMoOne==`x' & _j==7 // Job starts at x month in 2007
	replace JobOne1_2Yr=1 if BeginYrOne<2005 & EndYrOne>=2005 & BeginYrOne!=0 & _j==7 // Job started before 2005; filling Jan 2005 to indicate
	replace JobOne1_1Yr=1 if BeginYrOne<2006 & EndYrOne>=2006 & BeginYrOne!=0 & _j==7  // Job started before 2006; filling Jan 2006 to indicate
	replace JobOne1_CYr=1 if BeginYrOne<2007 & EndYrOne>=2007 & BeginYrOne!=0 & _j==7 // Job started before 2007; filling Jan 2007 to indicate
	replace JobOne`x'_2Yr=2 if EndYrOne==2005 & EndMoOne==`x' & _j==7 // Job ended at x month in 2005
	replace JobOne`x'_1Yr=2 if EndYrOne==2006 & EndMoOne==`x' & _j==7 // Job ended at x month in 2006
	replace JobOne`x'_CYr=2 if EndYrOne==2007 & EndMoOne==`x' & _j==7 // Job ended at x month in 2007
	
	*Job two
	replace JobTwo`x'_2Yr=1 if BeginYrTwo==2005 & BeginMoTwo==`x' & _j==7 // Job starts at x month in 2005
	replace JobTwo`x'_1Yr=1 if BeginYrTwo==2006 & BeginMoTwo==`x' & _j==7 // Job starts at x month in 2006
	replace JobTwo`x'_CYr=1 if BeginYrTwo==2007 & BeginMoTwo==`x' & _j==7 // Job starts at x month in 2007
	replace JobTwo1_2Yr=1 if BeginYrTwo<2005 & EndYrTwo>=2005 & BeginYrTwo!=0 & _j==7 // Job started before 2005; filling Jan 2005 to indicate
	replace JobTwo1_1Yr=1 if BeginYrTwo<2006 & EndYrTwo>=2006 & BeginYrTwo!=0 & _j==7  // Job started before 2006; filling Jan 2006 to indicate
	replace JobTwo1_CYr=1 if BeginYrTwo<2007 & EndYrTwo>=2007 & BeginYrTwo!=0 & _j==7 // Job started before 2007; filling Jan 2007 to indicate
	replace JobTwo`x'_2Yr=2 if EndYrTwo==2005 & EndMoTwo==`x' & _j==7 // Job ended at x month in 2005
	replace JobTwo`x'_1Yr=2 if EndYrTwo==2006 & EndMoTwo==`x' & _j==7 // Job ended at x month in 2006
	replace JobTwo`x'_CYr=2 if EndYrTwo==2007 & EndMoTwo==`x' & _j==7 // Job ended at x month in 2007
	
	*Job three
	replace JobThree`x'_2Yr=1 if BeginYrThree==2005 & BeginMoThree==`x' & _j==7 // Job starts at x month in 2005
	replace JobThree`x'_1Yr=1 if BeginYrThree==2006 & BeginMoThree==`x' & _j==7 // Job starts at x month in 2006
	replace JobThree`x'_CYr=1 if BeginYrThree==2007 & BeginMoThree==`x' & _j==7 // Job starts at x month in 2007
	replace JobThree1_2Yr=1 if BeginYrThree<2005 & EndYrThree>=2005 & BeginYrThree!=0 & _j==7 // Job started before 2005; filling Jan 2005 to indicate
	replace JobThree1_1Yr=1 if BeginYrThree<2006 & EndYrThree>=2006 & BeginYrThree!=0 & _j==7  // Job started before 2006; filling Jan 2006 to indicate
	replace JobThree1_CYr=1 if BeginYrThree<2007 & EndYrThree>=2007 & BeginYrThree!=0 & _j==7 // Job started before 2007; filling Jan 2007 to indicate
	replace JobThree`x'_2Yr=2 if EndYrThree==2005 & EndMoThree==`x' & _j==7 // Job ended at x month in 2005
	replace JobThree`x'_1Yr=2 if EndYrThree==2006 & EndMoThree==`x' & _j==7 // Job ended at x month in 2006
	replace JobThree`x'_CYr=2 if EndYrThree==2007 & EndMoThree==`x' & _j==7 // Job ended at x month in 2007
	
	*Job four
	replace JobFour`x'_2Yr=1 if BeginYrFour==2005 & BeginMoFour==`x' & _j==7 // Job starts at x month in 2005
	replace JobFour`x'_1Yr=1 if BeginYrFour==2006 & BeginMoFour==`x' & _j==7 // Job starts at x month in 2006
	replace JobFour`x'_CYr=1 if BeginYrFour==2007 & BeginMoFour==`x' & _j==7 // Job starts at x month in 2007
	replace JobFour1_2Yr=1 if BeginYrFour<2005 & EndYrFour>=2005 & BeginYrFour!=0 & _j==7 // Job started before 2005; filling Jan 2005 to indicate
	replace JobFour1_1Yr=1 if BeginYrFour<2006 & EndYrFour>=2006 & BeginYrFour!=0 & _j==7  // Job started before 2006; filling Jan 2006 to indicate
	replace JobFour1_CYr=1 if BeginYrFour<2007 & EndYrFour>=2007 & BeginYrFour!=0 & _j==7 // Job started before 2007; filling Jan 2007 to indicate
	replace JobFour`x'_2Yr=2 if EndYrFour==2005 & EndMoFour==`x' & _j==7 // Job ended at x month in 2005
	replace JobFour`x'_1Yr=2 if EndYrFour==2006 & EndMoFour==`x' & _j==7 // Job ended at x month in 2006
	replace JobFour`x'_CYr=2 if EndYrFour==2007 & EndMoFour==`x' & _j==7 // Job ended at x month in 2007
	
	*Job five
	replace JobFive`x'_2Yr=1 if BeginYrFive==2005 & BeginMoFive==`x' & _j==7 // Job starts at x month in 2005
	replace JobFive`x'_1Yr=1 if BeginYrFive==2006 & BeginMoFive==`x' & _j==7 // Job starts at x month in 2006
	replace JobFive`x'_CYr=1 if BeginYrFive==2007 & BeginMoFive==`x' & _j==7 // Job starts at x month in 2007
	replace JobFive1_2Yr=1 if BeginYrFive<2005 & EndYrFive>=2005 & BeginYrFive!=0 & _j==7 // Job started before 2005; filling Jan 2005 to indicate
	replace JobFive1_1Yr=1 if BeginYrFive<2006 & EndYrFive>=2006 & BeginYrFive!=0 & _j==7  // Job started before 2006; filling Jan 2006 to indicate
	replace JobFive1_CYr=1 if BeginYrFive<2007 & EndYrFive>=2007 & BeginYrFive!=0 & _j==7 // Job started before 2007; filling Jan 2007 to indicate
	replace JobFive`x'_2Yr=2 if EndYrFive==2005 & EndMoFive==`x' & _j==7 // Job ended at x month in 2005
	replace JobFive`x'_1Yr=2 if EndYrFive==2006 & EndMoFive==`x' & _j==7 // Job ended at x month in 2006
	replace JobFive`x'_CYr=2 if EndYrFive==2007 & EndMoFive==`x' & _j==7 // Job ended at x month in 2007
	}
	
		
		
*2009 2 YEAR EMPLOYMENT DATA

*TWO YEAR				ONE YEAR
*------------			--------------
*JAN 07		1			JAN 08		13
*FEB 07		2			FEB 08		14
*MAR 07		3			MAR 08		15
*APR 07		4			APR 08		16
*MAY 07		5			MAY 08		17
*JUN 07		6			JUN 08		18
*JUL 07		7			JUL 08		19
*AUG 07		8			AUG 08		20
*SEP 07		9			SEP 08		21
*OCT 07		10			OCT 08		22
*NOV 07		11			NOV 08		23
*DEC 07		12			DEC 08		24

foreach x in 1 2 3 4 5 6 7 8 9 10 11 12 {
	*Job one
	replace JobOne`x'_2Yr=1 if BeginYrOne==2007 & BeginMoOne==`x' & _j==9 // Job starts at x month in 2007
	replace JobOne`x'_1Yr=1 if BeginYrOne==2008 & BeginMoOne==`x' & _j==9 // Job starts at x month in 2008
	replace JobOne`x'_CYr=1 if BeginYrOne==2009 & BeginMoOne==`x' & _j==9 // Job starts at x month in 2009
	replace JobOne1_2Yr=1 if BeginYrOne<2007 & EndYrOne>=2007 & BeginYrOne!=0 & _j==9 // Job started before 2007; filling Jan 2007 to indicate
	replace JobOne1_1Yr=1 if BeginYrOne<2008 & EndYrOne>=2008 & BeginYrOne!=0 & _j==9  // Job started before 2008; filling Jan 2008 to indicate
	replace JobOne1_CYr=1 if BeginYrOne<2009 & EndYrOne>=2009 & BeginYrOne!=0 & _j==9 // Job started before 2009; filling Jan 2009 to indicate
	replace JobOne`x'_2Yr=2 if EndYrOne==2007 & EndMoOne==`x' & _j==9 // Job ended at x month in 2007
	replace JobOne`x'_1Yr=2 if EndYrOne==2008 & EndMoOne==`x' & _j==9 // Job ended at x month in 2008
	replace JobOne`x'_CYr=2 if EndYrOne==2009 & EndMoOne==`x' & _j==9 // Job ended at x month in 2009
	
	*Job two
	replace JobTwo`x'_2Yr=1 if BeginYrTwo==2007 & BeginMoTwo==`x' & _j==9 // Job starts at x month in 2007
	replace JobTwo`x'_1Yr=1 if BeginYrTwo==2008 & BeginMoTwo==`x' & _j==9 // Job starts at x month in 2008
	replace JobTwo`x'_CYr=1 if BeginYrTwo==2009 & BeginMoTwo==`x' & _j==9 // Job starts at x month in 2009
	replace JobTwo1_2Yr=1 if BeginYrTwo<2007 & EndYrOne>=2007 & BeginYrTwo!=0 & _j==9 // Job started before 2007; filling Jan 2007 to indicate
	replace JobTwo1_1Yr=1 if BeginYrTwo<2008 & EndYrOne>=2008 & BeginYrTwo!=0 & _j==9  // Job started before 2008; filling Jan 2008 to indicate
	replace JobTwo1_CYr=1 if BeginYrTwo<2009 & EndYrOne>=2009 & BeginYrTwo!=0 & _j==9 // Job started before 2009; filling Jan 2009 to indicate
	replace JobTwo`x'_2Yr=2 if EndYrTwo==2007 & EndMoTwo==`x' & _j==9 // Job ended at x month in 2007
	replace JobTwo`x'_1Yr=2 if EndYrTwo==2008 & EndMoTwo==`x' & _j==9 // Job ended at x month in 2008
	replace JobTwo`x'_CYr=2 if EndYrTwo==2009 & EndMoTwo==`x' & _j==9 // Job ended at x month in 2009
	
	*Job three
	replace JobThree`x'_2Yr=1 if BeginYrThree==2007 & BeginMoThree==`x' & _j==9 // Job starts at x month in 2007
	replace JobThree`x'_1Yr=1 if BeginYrThree==2008 & BeginMoThree==`x' & _j==9 // Job starts at x month in 2008
	replace JobThree`x'_CYr=1 if BeginYrThree==2009 & BeginMoThree==`x' & _j==9 // Job starts at x month in 2009
	replace JobThree1_2Yr=1 if BeginYrThree<2007 & EndYrOne>=2007 & BeginYrThree!=0 & _j==9 // Job started before 2007; filling Jan 2007 to indicate
	replace JobThree1_1Yr=1 if BeginYrThree<2008 & EndYrOne>=2008 & BeginYrThree!=0 & _j==9  // Job started before 2008; filling Jan 2008 to indicate
	replace JobThree1_CYr=1 if BeginYrThree<2009 & EndYrOne>=2009 & BeginYrThree!=0 & _j==9 // Job started before 2009; filling Jan 2009 to indicate
	replace JobThree`x'_2Yr=2 if EndYrThree==2007 & EndMoThree==`x' & _j==9 // Job ended at x month in 2007
	replace JobThree`x'_1Yr=2 if EndYrThree==2008 & EndMoThree==`x' & _j==9 // Job ended at x month in 2008
	replace JobThree`x'_CYr=2 if EndYrThree==2009 & EndMoThree==`x' & _j==9 // Job ended at x month in 2009
	
	*Job four
	replace JobFour`x'_2Yr=1 if BeginYrFour==2007 & BeginMoFour==`x' & _j==9 // Job starts at x month in 2007
	replace JobFour`x'_1Yr=1 if BeginYrFour==2008 & BeginMoFour==`x' & _j==9 // Job starts at x month in 2008
	replace JobFour`x'_CYr=1 if BeginYrFour==2009 & BeginMoFour==`x' & _j==9 // Job starts at x month in 2009
	replace JobFour1_2Yr=1 if BeginYrFour<2007 & EndYrOne>=2007 & BeginYrFour!=0 & _j==9 // Job started before 2007; filling Jan 2007 to indicate
	replace JobFour1_1Yr=1 if BeginYrFour<2008 & EndYrOne>=2008 & BeginYrFour!=0 & _j==9  // Job started before 2008; filling Jan 2008 to indicate
	replace JobFour1_CYr=1 if BeginYrFour<2009 & EndYrOne>=2009 & BeginYrFour!=0 & _j==9 // Job started before 2009; filling Jan 2009 to indicate
	replace JobFour`x'_2Yr=2 if EndYrFour==2007 & EndMoFour==`x' & _j==9 // Job ended at x month in 2007
	replace JobFour`x'_1Yr=2 if EndYrFour==2008 & EndMoFour==`x' & _j==9 // Job ended at x month in 2008
	replace JobFour`x'_CYr=2 if EndYrFour==2009 & EndMoFour==`x' & _j==9 // Job ended at x month in 2009
	
	*Job five
	replace JobFive`x'_2Yr=1 if BeginYrFive==2007 & BeginMoFive==`x' & _j==9 // Job starts at x month in 2007
	replace JobFive`x'_1Yr=1 if BeginYrFive==2008 & BeginMoFive==`x' & _j==9 // Job starts at x month in 2008
	replace JobFive`x'_CYr=1 if BeginYrFive==2009 & BeginMoFive==`x' & _j==9 // Job starts at x month in 2009
	replace JobFive1_2Yr=1 if BeginYrFive<2007 & EndYrOne>=2007 & BeginYrFive!=0 & _j==9 // Job started before 2007; filling Jan 2007 to indicate
	replace JobFive1_1Yr=1 if BeginYrFive<2008 & EndYrOne>=2008 & BeginYrFive!=0 & _j==9  // Job started before 2008; filling Jan 2008 to indicate
	replace JobFive1_CYr=1 if BeginYrFive<2009 & EndYrOne>=2009 & BeginYrFive!=0 & _j==9 // Job started before 2009; filling Jan 2009 to indicate
	replace JobFive`x'_2Yr=2 if EndYrFive==2007 & EndMoFive==`x' & _j==9 // Job ended at x month in 2007
	replace JobFive`x'_1Yr=2 if EndYrFive==2008 & EndMoFive==`x' & _j==9 // Job ended at x month in 2008
	replace JobFive`x'_CYr=2 if EndYrFive==2009 & EndMoFive==`x' & _j==9 // Job ended at x month in 2009
	}	
		
		
		
		
		

		
*2011 2 YEAR EMPLOYMENT DATA

*TWO YEAR				ONE YEAR
*------------			--------------
*JAN 09		1			JAN 10		13
*FEB 09		2			FEB 10		14
*MAR 09		3			MAR 10		15
*APR 09		4			APR 10		16
*MAY 09		5			MAY 10		17
*JUN 09		6			JUN 10		18
*JUL 09		7			JUL 10		19
*AUG 09		8			AUG 10		20
*SEP 09		9			SEP 10		21
*OCT 09		10			OCT 10		22
*NOV 09		11			NOV 10		23
*DEC 09		12			DEC 10		24

foreach x in 1 2 3 4 5 6 7 8 9 10 11 12 {
	*Job one
	replace JobOne`x'_2Yr=1 if BeginYrOne==2009 & BeginMoOne==`x' & _j==11 // Job starts at x month in 2009
	replace JobOne`x'_1Yr=1 if BeginYrOne==2010 & BeginMoOne==`x' & _j==11 // Job starts at x month in 2010
	replace JobOne`x'_CYr=1 if BeginYrOne==2011 & BeginMoOne==`x' & _j==11 // Job starts at x month in 2011
	replace JobOne1_2Yr=1 if BeginYrOne<2009 & EndYrOne>=2009 & BeginYrOne!=0 & _j==11 // Job started before 2009; filling Jan 2009 to indicate
	replace JobOne1_1Yr=1 if BeginYrOne<2010 & EndYrOne>=2010 & BeginYrOne!=0 & _j==11  // Job started before 2010; filling Jan 2010 to indicate
	replace JobOne1_CYr=1 if BeginYrOne<2011 & EndYrOne>=2011 & BeginYrOne!=0 & _j==11 // Job started before 2011; filling Jan 2011 to indicate
	replace JobOne`x'_2Yr=2 if EndYrOne==2009 & EndMoOne==`x' & _j==11 // Job ended at x month in 2009
	replace JobOne`x'_1Yr=2 if EndYrOne==2010 & EndMoOne==`x' & _j==11 // Job ended at x month in 2010
	replace JobOne`x'_CYr=2 if EndYrOne==2011 & EndMoOne==`x' & _j==11 // Job ended at x month in 2011
	
	*Job two
	replace JobTwo`x'_2Yr=1 if BeginYrTwo==2009 & BeginMoTwo==`x' & _j==11 // Job starts at x month in 2009
	replace JobTwo`x'_1Yr=1 if BeginYrTwo==2010 & BeginMoTwo==`x' & _j==11 // Job starts at x month in 2010
	replace JobTwo`x'_CYr=1 if BeginYrTwo==2011 & BeginMoTwo==`x' & _j==11 // Job starts at x month in 2011
	replace JobTwo1_2Yr=1 if BeginYrTwo<2009 & EndYrTwo>=2009 & BeginYrTwo!=0 & _j==11 // Job started before 2009; filling Jan 2009 to indicate
	replace JobTwo1_1Yr=1 if BeginYrTwo<2010 & EndYrTwo>=2010 & BeginYrTwo!=0 & _j==11  // Job started before 2010; filling Jan 2010 to indicate
	replace JobTwo1_CYr=1 if BeginYrTwo<2011 & EndYrTwo>=2011 & BeginYrTwo!=0 & _j==11 // Job started before 2011; filling Jan 2011 to indicate
	replace JobTwo`x'_2Yr=2 if EndYrTwo==2009 & EndMoTwo==`x' & _j==11 // Job ended at x month in 2009
	replace JobTwo`x'_1Yr=2 if EndYrTwo==2010 & EndMoTwo==`x' & _j==11 // Job ended at x month in 2010
	replace JobTwo`x'_CYr=2 if EndYrTwo==2011 & EndMoTwo==`x' & _j==11 // Job ended at x month in 2011
	
	*Job three
	replace JobThree`x'_2Yr=1 if BeginYrThree==2009 & BeginMoThree==`x' & _j==11 // Job starts at x month in 2009
	replace JobThree`x'_1Yr=1 if BeginYrThree==2010 & BeginMoThree==`x' & _j==11 // Job starts at x month in 2010
	replace JobThree`x'_CYr=1 if BeginYrThree==2011 & BeginMoThree==`x' & _j==11 // Job starts at x month in 2011
	replace JobThree1_2Yr=1 if BeginYrThree<2009 & EndYrThree>=2009 & BeginYrThree!=0 & _j==11 // Job started before 2009; filling Jan 2009 to indicate
	replace JobThree1_1Yr=1 if BeginYrThree<2010 & EndYrThree>=2010 & BeginYrThree!=0 & _j==11  // Job started before 2010; filling Jan 2010 to indicate
	replace JobThree1_CYr=1 if BeginYrThree<2011 & EndYrThree>=2011 & BeginYrThree!=0 & _j==11 // Job started before 2011; filling Jan 2011 to indicate
	replace JobThree`x'_2Yr=2 if EndYrThree==2009 & EndMoThree==`x' & _j==11 // Job ended at x month in 2009
	replace JobThree`x'_1Yr=2 if EndYrThree==2010 & EndMoThree==`x' & _j==11 // Job ended at x month in 2010
	replace JobThree`x'_CYr=2 if EndYrThree==2011 & EndMoThree==`x' & _j==11 // Job ended at x month in 2011
	
	*Job four
	replace JobFour`x'_2Yr=1 if BeginYrFour==2009 & BeginMoFour==`x' & _j==11 // Job starts at x month in 2009
	replace JobFour`x'_1Yr=1 if BeginYrFour==2010 & BeginMoFour==`x' & _j==11 // Job starts at x month in 2010
	replace JobFour`x'_CYr=1 if BeginYrFour==2011 & BeginMoFour==`x' & _j==11 // Job starts at x month in 2011
	replace JobFour1_2Yr=1 if BeginYrFour<2009 & EndYrFour>=2009 & BeginYrFour!=0 & _j==11 // Job started before 2009; filling Jan 2009 to indicate
	replace JobFour1_1Yr=1 if BeginYrFour<2010 & EndYrFour>=2010 & BeginYrFour!=0 & _j==11  // Job started before 2010; filling Jan 2010 to indicate
	replace JobFour1_CYr=1 if BeginYrFour<2011 & EndYrFour>=2011 & BeginYrFour!=0 & _j==11 // Job started before 2011; filling Jan 2011 to indicate
	replace JobFour`x'_2Yr=2 if EndYrFour==2009 & EndMoFour==`x' & _j==11 // Job ended at x month in 2009
	replace JobFour`x'_1Yr=2 if EndYrFour==2010 & EndMoFour==`x' & _j==11 // Job ended at x month in 2010
	replace JobFour`x'_CYr=2 if EndYrFour==2011 & EndMoFour==`x' & _j==11 // Job ended at x month in 2011
	
	*Job five
	replace JobFive`x'_2Yr=1 if BeginYrFive==2009 & BeginMoFive==`x' & _j==11 // Job starts at x month in 2009
	replace JobFive`x'_1Yr=1 if BeginYrFive==2010 & BeginMoFive==`x' & _j==11 // Job starts at x month in 2010
	replace JobFive`x'_CYr=1 if BeginYrFive==2011 & BeginMoFive==`x' & _j==11 // Job starts at x month in 2011
	replace JobFive1_2Yr=1 if BeginYrFive<2009 & EndYrFive>=2009 & BeginYrFive!=0 & _j==11 // Job started before 2009; filling Jan 2009 to indicate
	replace JobFive1_1Yr=1 if BeginYrFive<2010 & EndYrFive>=2010 & BeginYrFive!=0 & _j==11  // Job started before 2010; filling Jan 2010 to indicate
	replace JobFive1_CYr=1 if BeginYrFive<2011 & EndYrFive>=2011 & BeginYrFive!=0 & _j==11 // Job started before 2011; filling Jan 2011 to indicate
	replace JobFive`x'_2Yr=2 if EndYrFive==2009 & EndMoFive==`x' & _j==11 // Job ended at x month in 2009
	replace JobFive`x'_1Yr=2 if EndYrFive==2010 & EndMoFive==`x' & _j==11 // Job ended at x month in 2010
	replace JobFive`x'_CYr=2 if EndYrFive==2011 & EndMoFive==`x' & _j==11 // Job ended at x month in 2011
	}
		
		
		
		
		
		
*2013 2 YEAR EMPLOYMENT DATA

*TWO YEAR				ONE YEAR
*------------			--------------
*JAN 11		1			JAN 12		13
*FEB 11		2			FEB 12		14
*MAR 11		3			MAR 12		15
*APR 11		4			APR 12		16
*MAY 11		5			MAY 12		17
*JUN 11		6			JUN 12		18
*JUL 11		7			JUL 12		19
*AUG 11		8			AUG 12		20
*SEP 11		9			SEP 12		21
*OCT 11		10			OCT 12		22
*NOV 11		11			NOV 12		23
*DEC 11		12			DEC 12		24

foreach x in 1 2 3 4 5 6 7 8 9 10 11 12 {
	*Job one
	replace JobOne`x'_2Yr=1 if BeginYrOne==2011 & BeginMoOne==`x' & _j==13 // Job starts at x month in 2011
	replace JobOne`x'_1Yr=1 if BeginYrOne==2012 & BeginMoOne==`x' & _j==13 // Job starts at x month in 2012
	replace JobOne`x'_CYr=1 if BeginYrOne==2013 & BeginMoOne==`x' & _j==13 // Job starts at x month in 2013
	replace JobOne1_2Yr=1 if BeginYrOne<2011 & EndYrOne>=2011 & BeginYrOne!=0 & _j==13 // Job started before 2011; filling Jan 2011 to indicate
	replace JobOne1_1Yr=1 if BeginYrOne<2012 & EndYrOne>=2012 & BeginYrOne!=0 & _j==13  // Job started before 2012; filling Jan 2012 to indicate
	replace JobOne1_CYr=1 if BeginYrOne<2013 & EndYrOne>=2013 & BeginYrOne!=0 & _j==13 // Job started before 2013; filling Jan 2013 to indicate
	replace JobOne`x'_2Yr=2 if EndYrOne==2011 & EndMoOne==`x' & _j==13 // Job ended at x month in 2011
	replace JobOne`x'_1Yr=2 if EndYrOne==2012 & EndMoOne==`x' & _j==13 // Job ended at x month in 2012
	replace JobOne`x'_CYr=2 if EndYrOne==2013 & EndMoOne==`x' & _j==13 // Job ended at x month in 2013
	
	*Job two
	replace JobTwo`x'_2Yr=1 if BeginYrTwo==2011 & BeginMoTwo==`x' & _j==13 // Job starts at x month in 2011
	replace JobTwo`x'_1Yr=1 if BeginYrTwo==2012 & BeginMoTwo==`x' & _j==13 // Job starts at x month in 2012
	replace JobTwo`x'_CYr=1 if BeginYrTwo==2013 & BeginMoTwo==`x' & _j==13 // Job starts at x month in 2013
	replace JobTwo1_2Yr=1 if BeginYrTwo<2011 & EndYrTwo>=2011 & BeginYrTwo!=0 & _j==13 // Job started before 2011; filling Jan 2011 to indicate
	replace JobTwo1_1Yr=1 if BeginYrTwo<2012 & EndYrTwo>=2012 & BeginYrTwo!=0 & _j==13  // Job started before 2012; filling Jan 2012 to indicate
	replace JobTwo1_CYr=1 if BeginYrTwo<2013 & EndYrTwo>=2013 & BeginYrTwo!=0 & _j==13 // Job started before 2013; filling Jan 2013 to indicate
	replace JobTwo`x'_2Yr=2 if EndYrTwo==2011 & EndMoTwo==`x' & _j==13 // Job ended at x month in 2011
	replace JobTwo`x'_1Yr=2 if EndYrTwo==2012 & EndMoTwo==`x' & _j==13 // Job ended at x month in 2012
	replace JobTwo`x'_CYr=2 if EndYrTwo==2013 & EndMoTwo==`x' & _j==13 // Job ended at x month in 2013
	
	*Job three
	replace JobThree`x'_2Yr=1 if BeginYrThree==2011 & BeginMoThree==`x' & _j==13 // Job starts at x month in 2011
	replace JobThree`x'_1Yr=1 if BeginYrThree==2012 & BeginMoThree==`x' & _j==13 // Job starts at x month in 2012
	replace JobThree`x'_CYr=1 if BeginYrThree==2013 & BeginMoThree==`x' & _j==13 // Job starts at x month in 2013
	replace JobThree1_2Yr=1 if BeginYrThree<2011 & EndYrThree>=2011 & BeginYrThree!=0 & _j==13 // Job started before 2011; filling Jan 2011 to indicate
	replace JobThree1_1Yr=1 if BeginYrThree<2012 & EndYrThree>=2012 & BeginYrThree!=0 & _j==13  // Job started before 2012; filling Jan 2012 to indicate
	replace JobThree1_CYr=1 if BeginYrThree<2013 & EndYrThree>=2013 & BeginYrThree!=0 & _j==13 // Job started before 2013; filling Jan 2013 to indicate
	replace JobThree`x'_2Yr=2 if EndYrThree==2011 & EndMoThree==`x' & _j==13 // Job ended at x month in 2011
	replace JobThree`x'_1Yr=2 if EndYrThree==2012 & EndMoThree==`x' & _j==13 // Job ended at x month in 2012
	replace JobThree`x'_CYr=2 if EndYrThree==2013 & EndMoThree==`x' & _j==13 // Job ended at x month in 2013
	
	*Job four
	replace JobFour`x'_2Yr=1 if BeginYrFour==2011 & BeginMoFour==`x' & _j==13 // Job starts at x month in 2011
	replace JobFour`x'_1Yr=1 if BeginYrFour==2012 & BeginMoFour==`x' & _j==13 // Job starts at x month in 2012
	replace JobFour`x'_CYr=1 if BeginYrFour==2013 & BeginMoFour==`x' & _j==13 // Job starts at x month in 2013
	replace JobFour1_2Yr=1 if BeginYrFour<2011 & EndYrFour>=2011 & BeginYrFour!=0 & _j==13 // Job started before 2011; filling Jan 2011 to indicate
	replace JobFour1_1Yr=1 if BeginYrFour<2012 & EndYrFour>=2012 & BeginYrFour!=0 & _j==13  // Job started before 2012; filling Jan 2012 to indicate
	replace JobFour1_CYr=1 if BeginYrFour<2013 & EndYrFour>=2013 & BeginYrFour!=0 & _j==13 // Job started before 2013; filling Jan 2013 to indicate
	replace JobFour`x'_2Yr=2 if EndYrFour==2011 & EndMoFour==`x' & _j==13 // Job ended at x month in 2011
	replace JobFour`x'_1Yr=2 if EndYrFour==2012 & EndMoFour==`x' & _j==13 // Job ended at x month in 2012
	replace JobFour`x'_CYr=2 if EndYrFour==2013 & EndMoFour==`x' & _j==13 // Job ended at x month in 2013
	
	*Job five
	replace JobFive`x'_2Yr=1 if BeginYrFive==2011 & BeginMoFive==`x' & _j==13 // Job starts at x month in 2011
	replace JobFive`x'_1Yr=1 if BeginYrFive==2012 & BeginMoFive==`x' & _j==13 // Job starts at x month in 2012
	replace JobFive`x'_CYr=1 if BeginYrFive==2013 & BeginMoFive==`x' & _j==13 // Job starts at x month in 2013
	replace JobFive1_2Yr=1 if BeginYrFive<2011 & EndYrFive>=2011 & BeginYrFive!=0 & _j==13 // Job started before 2011; filling Jan 2011 to indicate
	replace JobFive1_1Yr=1 if BeginYrFive<2012 & EndYrFive>=2012 & BeginYrFive!=0 & _j==13  // Job started before 2012; filling Jan 2012 to indicate
	replace JobFive1_CYr=1 if BeginYrFive<2013 & EndYrFive>=2013 & BeginYrFive!=0 & _j==13 // Job started before 2013; filling Jan 2013 to indicate
	replace JobFive`x'_2Yr=2 if EndYrFive==2011 & EndMoFive==`x' & _j==13 // Job ended at x month in 2011
	replace JobFive`x'_1Yr=2 if EndYrFive==2012 & EndMoFive==`x' & _j==13 // Job ended at x month in 2012
	replace JobFive`x'_CYr=2 if EndYrFive==2013 & EndMoFive==`x' & _j==13 // Job ended at x month in 2013
	}		
		
		
		
	
*2015 2 YEAR EMPLOYMENT DATA

*TWO YEAR				ONE YEAR
*------------			--------------
*JAN 13		1			JAN 14		13
*FEB 13		2			FEB 14		14
*MAR 13		3			MAR 14		15
*APR 13		4			APR 14		16
*MAY 13		5			MAY 14		17
*JUN 13		6			JUN 14		18
*JUL 13		7			JUL 14		19
*AUG 13		8			AUG 14		20
*SEP 13		9			SEP 14		21
*OCT 13		10			OCT 14		22
*NOV 13		11			NOV 14		23
*DEC 13		12			DEC 14		24

foreach x in 1 2 3 4 5 6 7 8 9 10 11 12 {
	replace JobOne`x'_2Yr=1 if BeginYrOne==2013 & BeginMoOne==`x' & _j==15
	replace JobOne`x'_1Yr=1 if BeginYrOne==2014 & BeginMoOne==`x' & _j==15
	replace JobOne1_2Yr=1 if BeginYrOne<2013 & EndYrOne>=2013 & BeginYrOne!=0 & _j==15
	replace JobOne1_1Yr=1 if BeginYrOne<2014 & EndYrOne>=2014 & BeginYrOne!=0 & _j==15
	replace JobOne`x'_2Yr=2 if EndYrOne==2013 & EndMoOne==`x' & _j==15
	replace JobOne`x'_1Yr=2 if EndYrOne==2014 & EndMoOne==`x' & _j==15
	
	replace JobTwo`x'_2Yr=1 if BeginYrTwo==2013 & BeginMoTwo==`x' & _j==15
	replace JobTwo`x'_1Yr=1 if BeginYrTwo==2014 & BeginMoTwo==`x' & _j==15
	replace JobTwo1_2Yr=1 if BeginYrTwo<2013 & EndYrTwo>=2013 & BeginYrTwo!=0 & _j==15
	replace JobTwo1_1Yr=1 if BeginYrTwo<2014 & EndYrTwo>=2014 & BeginYrTwo!=0 & _j==15
	replace JobTwo`x'_2Yr=2 if EndYrTwo==2013 & EndMoTwo==`x' & _j==15
	replace JobTwo`x'_1Yr=2 if EndYrTwo==2014 & EndMoTwo==`x' & _j==15
	
	replace JobThree`x'_2Yr=1 if BeginYrThree==2013 & BeginMoThree==`x' & _j==15
	replace JobThree`x'_1Yr=1 if BeginYrThree==2014 & BeginMoThree==`x' & _j==15
	replace JobThree1_2Yr=1 if BeginYrThree<2013 & EndYrThree>=2013 & BeginYrThree!=0 & _j==15
	replace JobThree1_1Yr=1 if BeginYrThree<2014 & EndYrThree>=2014 & BeginYrThree!=0 & _j==15
	replace JobThree`x'_2Yr=2 if EndYrThree==2013 & EndMoThree==`x' & _j==15
	replace JobThree`x'_1Yr=2 if EndYrThree==2014 & EndMoThree==`x' & _j==15
	
	replace JobFour`x'_2Yr=1 if BeginYrFour==2013 & BeginMoFour==`x' & _j==15
	replace JobFour`x'_1Yr=1 if BeginYrFour==2014 & BeginMoFour==`x' & _j==15
	replace JobFour1_2Yr=1 if BeginYrFour<2013 & EndYrFour>=2013 & BeginYrFour!=0 & _j==15
	replace JobFour1_1Yr=1 if BeginYrFour<2014 & EndYrFour>=2014 & BeginYrFour!=0 & _j==15
	replace JobFour`x'_2Yr=2 if EndYrFour==2013 & EndMoFour==`x' & _j==15
	replace JobFour`x'_1Yr=2 if EndYrFour==2014 & EndMoFour==`x' & _j==15
	replace JobFour1_1Yr=1 if BeginYrFour<2014 & BeginYrFour!=0 & _j==15
	
	replace JobFive`x'_2Yr=1 if BeginYrFive==2013 & BeginMoFive==`x' & _j==15
	replace JobFive`x'_1Yr=1 if BeginYrFive==2014 & BeginMoFive==`x' & _j==15
	replace JobFive1_2Yr=1 if BeginYrFive<2013 & EndYrFive>=2013 & BeginYrFive!=0 & _j==15
	replace JobFive1_1Yr=1 if BeginYrFive<2014 & EndYrFive>=2014 & BeginYrFive!=0 & _j==15
	replace JobFive`x'_2Yr=2 if EndYrFive==2013 & EndMoFive==`x' & _j==15
	replace JobFive`x'_1Yr=2 if EndYrFive==2014 & EndMoFive==`x' & _j==15
	}	

	
	
	
*FILLING MONTHS IN BETWEEN START AND STOP DATES
*	1 = Start
*	2 = End
*	This loop fills all spaces between events 1 (start) and 2 (end) to indicate
*	monthly level employment between these start/stop months.
foreach x in 2 3 4 5 6 7 8 9 10 11 12 {
	local j = `x'-1
	replace JobOne`x'_1Yr=1 if JobOne`j'_1Yr==1 & JobOne`x'_1Yr!=2
	replace JobTwo`x'_1Yr=1 if JobTwo`j'_1Yr==1 & JobTwo`x'_1Yr!=2
	replace JobThree`x'_1Yr=1 if JobThree`j'_1Yr==1 & JobThree`x'_1Yr!=2
	replace JobFour`x'_1Yr=1 if JobFour`j'_1Yr==1 & JobFour`x'_1Yr!=2
	replace JobFive`x'_1Yr=1 if JobFive`j'_1Yr==1 & JobFive`x'_1Yr!=2
	replace JobOne`x'_2Yr=1 if JobOne`j'_2Yr==1 & JobOne`x'_2Yr!=2
	replace JobTwo`x'_2Yr=1 if JobTwo`j'_2Yr==1 & JobTwo`x'_2Yr!=2
	replace JobThree`x'_2Yr=1 if JobThree`j'_2Yr==1 & JobThree`x'_2Yr!=2
	replace JobFour`x'_2Yr=1 if JobFour`j'_2Yr==1 & JobFour`x'_2Yr!=2
	replace JobFive`x'_2Yr=1 if JobFive`j'_2Yr==1 & JobFive`x'_2Yr!=2
	replace JobOne`x'_CYr=1 if JobOne`j'_CYr==1 & JobOne`x'_CYr!=2
	replace JobTwo`x'_CYr=1 if JobTwo`j'_CYr==1 & JobTwo`x'_CYr!=2
	replace JobThree`x'_CYr=1 if JobThree`j'_CYr==1 & JobThree`x'_CYr!=2
	replace JobFour`x'_CYr=1 if JobFour`j'_CYr==1 & JobFour`x'_CYr!=2
	replace JobFive`x'_CYr=1 if JobFive`j'_CYr==1 & JobFive`x'_CYr!=2
	}
	
*Recoding 2 = 1 to create consistency
*	No longer need to indicate 2 as stop date, just need to know if employed.
foreach x in JobOne1_1Yr JobOne1_2Yr JobOne2_1Yr JobOne2_2Yr JobOne3_1Yr JobOne3_2Yr ///
	JobOne4_1Yr JobOne4_2Yr JobOne5_1Yr JobOne5_2Yr JobOne6_1Yr JobOne6_2Yr JobOne7_1Yr ///
	JobOne7_2Yr JobOne8_1Yr JobOne8_2Yr JobOne9_1Yr JobOne9_2Yr JobOne10_1Yr JobOne10_2Yr ///
	JobOne11_1Yr JobOne11_2Yr JobOne12_1Yr JobOne12_2Yr JobTwo1_1Yr JobTwo1_2Yr ///
	JobTwo2_1Yr JobTwo2_2Yr JobTwo3_1Yr JobTwo3_2Yr JobTwo4_1Yr JobTwo4_2Yr JobTwo5_1Yr ///
	JobTwo5_2Yr JobTwo6_1Yr JobTwo6_2Yr JobTwo7_1Yr JobTwo7_2Yr JobTwo8_1Yr JobTwo8_2Yr ///
	JobTwo9_1Yr JobTwo9_2Yr JobTwo10_1Yr JobTwo10_2Yr JobTwo11_1Yr JobTwo11_2Yr ///
	JobTwo12_1Yr JobTwo12_2Yr JobThree1_1Yr JobThree1_2Yr JobThree2_1Yr JobThree2_2Yr ///
	JobThree3_1Yr JobThree3_2Yr JobThree4_1Yr JobThree4_2Yr JobThree5_1Yr JobThree5_2Yr ///
	JobThree6_1Yr JobThree6_2Yr JobThree7_1Yr JobThree7_2Yr JobThree8_1Yr JobThree8_2Yr ///
	JobThree9_1Yr JobThree9_2Yr JobThree10_1Yr JobThree10_2Yr JobThree11_1Yr JobThree11_2Yr ///
	JobThree12_1Yr JobThree12_2Yr JobFour1_1Yr JobFour1_2Yr JobFour2_1Yr JobFour2_2Yr ///
	JobFour3_1Yr JobFour3_2Yr JobFour4_1Yr JobFour4_2Yr JobFour5_1Yr JobFour5_2Yr ///
	JobFour6_1Yr JobFour6_2Yr JobFour7_1Yr JobFour7_2Yr JobFour8_1Yr JobFour8_2Yr ///
	JobFour9_1Yr JobFour9_2Yr JobFour10_1Yr JobFour10_2Yr JobFour11_1Yr JobFour11_2Yr ///
	JobFour12_1Yr JobFour12_2Yr JobFive1_1Yr JobFive1_2Yr JobFive2_1Yr JobFive2_2Yr ///
	JobFive3_1Yr JobFive3_2Yr JobFive4_1Yr JobFive4_2Yr JobFive5_1Yr JobFive5_2Yr ///
	JobFive6_1Yr JobFive6_2Yr JobFive7_1Yr JobFive7_2Yr JobFive8_1Yr JobFive8_2Yr ///
	JobFive9_1Yr JobFive9_2Yr JobFive10_1Yr JobFive10_2Yr JobFive11_1Yr JobFive11_2Yr ///
	JobFive12_1Yr JobFive12_2Yr JobOne1_CYr JobOne2_CYr JobOne3_CYr JobOne4_CYr ///
	JobOne5_CYr JobOne6_CYr JobOne7_CYr JobOne8_CYr JobOne9_CYr JobOne10_CYr JobOne11_CYr ///
	JobOne12_CYr JobTwo1_CYr JobTwo2_CYr JobTwo3_CYr JobTwo4_CYr JobTwo5_CYr JobTwo6_CYr ///
	JobTwo7_CYr JobTwo8_CYr JobTwo9_CYr JobTwo10_CYr JobTwo11_CYr JobTwo12_CYr JobThree1_CYr ///
	JobThree2_CYr JobThree3_CYr JobThree4_CYr JobThree5_CYr JobThree6_CYr JobThree7_CYr ///
	JobThree8_CYr JobThree9_CYr JobThree10_CYr JobThree11_CYr JobThree12_CYr JobFour1_CYr ///
	JobFour2_CYr JobFour3_CYr JobFour4_CYr JobFour5_CYr JobFour6_CYr JobFour7_CYr ///
	JobFour8_CYr JobFour9_CYr JobFour10_CYr JobFour11_CYr JobFour12_CYr JobFive1_CYr ///
	JobFive2_CYr JobFive3_CYr JobFive4_CYr JobFive5_CYr JobFive6_CYr JobFive7_CYr ///
	JobFive8_CYr JobFive9_CYr JobFive10_CYr JobFive11_CYr JobFive12_CYr {
	recode `x' 2=1
	}
	
*CONDENSING ALL JOBS INTO 12 MONTH PERIODS
*	Determining all months of employment based on 5 reported jobs.	
foreach x in 1 2 3 4 5 6 7 8 9 10 11 12 {
	egen OneYear`x'=rowmax(JobOne`x'_1Yr JobTwo`x'_1Yr JobThree`x'_1Yr JobFour`x'_1Yr JobFive`x'_1Yr)
	egen TwoYear`x'=rowmax(JobOne`x'_2Yr JobTwo`x'_2Yr JobThree`x'_2Yr JobFour`x'_2Yr JobFive`x'_2Yr)
	egen CYear`x'=rowmax(JobOne`x'_CYr JobTwo`x'_CYr JobThree`x'_CYr JobFour`x'_CYr JobFive`x'_CYr)
	}

keep ParticipantID _j TwoYear* OneYear* CYear*

foreach x in TwoYear OneYear CYear {
	foreach y of num 1/12 {
		rename `x'`y' OG_`x'`y'_
		}
	}

reshape wide OG_TwoYear* OG_OneYear* OG_CYear*, i(ParticipantID) j(_j)


* CONDENSING OVERLAPPING YEARS
*	wave     2yr     1yr     Cyr
*--------+-----------------------
*	 5   |    3       4       5
*	 7   |    5       6       7
*	 9   |    7       8       9
*	11   |    9      10      11
*	13   |   11      12      13
*	15   |   13      14      15
*--------+-----------------------


*Generating 144 month calendar to fill
foreach x of numlist 1/144 {
	gen Employed`x'=.
	}

*Filling 144 months with corresponding TwoYear OneYear and CYear values
replace	Employed1	=	1	if	OG_TwoYear1_5	==	1				
replace	Employed2	=	1	if	OG_TwoYear2_5	==	1				
replace	Employed3	=	1	if	OG_TwoYear3_5	==	1				
replace	Employed4	=	1	if	OG_TwoYear4_5	==	1				
replace	Employed5	=	1	if	OG_TwoYear5_5	==	1				
replace	Employed6	=	1	if	OG_TwoYear6_5	==	1				
replace	Employed7	=	1	if	OG_TwoYear7_5	==	1				
replace	Employed8	=	1	if	OG_TwoYear8_5	==	1				
replace	Employed9	=	1	if	OG_TwoYear9_5	==	1				
replace	Employed10	=	1	if	OG_TwoYear10_5	==	1				
replace	Employed11	=	1	if	OG_TwoYear11_5	==	1				
replace	Employed12	=	1	if	OG_TwoYear12_5	==	1				
replace	Employed13	=	1	if	OG_OneYear1_5	==	1				
replace	Employed14	=	1	if	OG_OneYear2_5	==	1				
replace	Employed15	=	1	if	OG_OneYear3_5	==	1				
replace	Employed16	=	1	if	OG_OneYear4_5	==	1				
replace	Employed17	=	1	if	OG_OneYear5_5	==	1				
replace	Employed18	=	1	if	OG_OneYear6_5	==	1				
replace	Employed19	=	1	if	OG_OneYear7_5	==	1				
replace	Employed20	=	1	if	OG_OneYear8_5	==	1				
replace	Employed21	=	1	if	OG_OneYear9_5	==	1				
replace	Employed22	=	1	if	OG_OneYear10_5	==	1				
replace	Employed23	=	1	if	OG_OneYear11_5	==	1				
replace	Employed24	=	1	if	OG_OneYear12_5	==	1				
replace	Employed25	=	1	if	OG_TwoYear1_7	==	1	|	OG_CYear1_5	==	1
replace	Employed26	=	1	if	OG_TwoYear2_7	==	1	|	OG_CYear2_5	==	1
replace	Employed27	=	1	if	OG_TwoYear3_7	==	1	|	OG_CYear3_5	==	1
replace	Employed28	=	1	if	OG_TwoYear4_7	==	1	|	OG_CYear4_5	==	1
replace	Employed29	=	1	if	OG_TwoYear5_7	==	1	|	OG_CYear5_5	==	1
replace	Employed30	=	1	if	OG_TwoYear6_7	==	1	|	OG_CYear6_5	==	1
replace	Employed31	=	1	if	OG_TwoYear7_7	==	1	|	OG_CYear7_5	==	1
replace	Employed32	=	1	if	OG_TwoYear8_7	==	1	|	OG_CYear8_5	==	1
replace	Employed33	=	1	if	OG_TwoYear9_7	==	1	|	OG_CYear9_5	==	1
replace	Employed34	=	1	if	OG_TwoYear10_7	==	1	|	OG_CYear10_5 ==	1
replace	Employed35	=	1	if	OG_TwoYear11_7	==	1	|	OG_CYear11_5 ==	1
replace	Employed36	=	1	if	OG_TwoYear12_7	==	1	|	OG_CYear12_5 ==	1
replace	Employed37	=	1	if	OG_OneYear1_7	==	1				
replace	Employed38	=	1	if	OG_OneYear2_7	==	1				
replace	Employed39	=	1	if	OG_OneYear3_7	==	1				
replace	Employed40	=	1	if	OG_OneYear4_7	==	1				
replace	Employed41	=	1	if	OG_OneYear5_7	==	1				
replace	Employed42	=	1	if	OG_OneYear6_7	==	1				
replace	Employed43	=	1	if	OG_OneYear7_7	==	1				
replace	Employed44	=	1	if	OG_OneYear8_7	==	1				
replace	Employed45	=	1	if	OG_OneYear9_7	==	1				
replace	Employed46	=	1	if	OG_OneYear10_7	==	1				
replace	Employed47	=	1	if	OG_OneYear11_7	==	1				
replace	Employed48	=	1	if	OG_OneYear12_7	==	1				
replace	Employed49	=	1	if	OG_TwoYear1_9	==	1	|	OG_CYear1_7	==	1
replace	Employed50	=	1	if	OG_TwoYear2_9	==	1	|	OG_CYear2_7	==	1
replace	Employed51	=	1	if	OG_TwoYear3_9	==	1	|	OG_CYear3_7	==	1
replace	Employed52	=	1	if	OG_TwoYear4_9	==	1	|	OG_CYear4_7	==	1
replace	Employed53	=	1	if	OG_TwoYear5_9	==	1	|	OG_CYear5_7	==	1
replace	Employed54	=	1	if	OG_TwoYear6_9	==	1	|	OG_CYear6_7	==	1
replace	Employed55	=	1	if	OG_TwoYear7_9	==	1	|	OG_CYear7_7	==	1
replace	Employed56	=	1	if	OG_TwoYear8_9	==	1	|	OG_CYear8_7	==	1
replace	Employed57	=	1	if	OG_TwoYear9_9	==	1	|	OG_CYear9_7	==	1
replace	Employed58	=	1	if	OG_TwoYear10_9	==	1	|	OG_CYear10_7 ==	1
replace	Employed59	=	1	if	OG_TwoYear11_9	==	1	|	OG_CYear11_7 ==	1
replace	Employed60	=	1	if	OG_TwoYear12_9	==	1	|	OG_CYear12_7 ==	1
replace	Employed61	=	1	if	OG_OneYear1_9	==	1				
replace	Employed62	=	1	if	OG_OneYear2_9	==	1				
replace	Employed63	=	1	if	OG_OneYear3_9	==	1				
replace	Employed64	=	1	if	OG_OneYear4_9	==	1				
replace	Employed65	=	1	if	OG_OneYear5_9	==	1				
replace	Employed66	=	1	if	OG_OneYear6_9	==	1				
replace	Employed67	=	1	if	OG_OneYear7_9	==	1				
replace	Employed68	=	1	if	OG_OneYear8_9	==	1				
replace	Employed69	=	1	if	OG_OneYear9_9	==	1				
replace	Employed70	=	1	if	OG_OneYear10_9	==	1				
replace	Employed71	=	1	if	OG_OneYear11_9	==	1				
replace	Employed72	=	1	if	OG_OneYear12_9	==	1				
replace	Employed73	=	1	if	OG_TwoYear1_11	==	1	|	OG_CYear1_9	==	1
replace	Employed74	=	1	if	OG_TwoYear2_11	==	1	|	OG_CYear2_9	==	1
replace	Employed75	=	1	if	OG_TwoYear3_11	==	1	|	OG_CYear3_9	==	1
replace	Employed76	=	1	if	OG_TwoYear4_11	==	1	|	OG_CYear4_9	==	1
replace	Employed77	=	1	if	OG_TwoYear5_11	==	1	|	OG_CYear5_9	==	1
replace	Employed78	=	1	if	OG_TwoYear6_11	==	1	|	OG_CYear6_9	==	1
replace	Employed79	=	1	if	OG_TwoYear7_11	==	1	|	OG_CYear7_9	==	1
replace	Employed80	=	1	if	OG_TwoYear8_11	==	1	|	OG_CYear8_9	==	1
replace	Employed81	=	1	if	OG_TwoYear9_11	==	1	|	OG_CYear9_9	==	1
replace	Employed82	=	1	if	OG_TwoYear10_11	==	1	|	OG_CYear10_9 ==	1
replace	Employed83	=	1	if	OG_TwoYear11_11	==	1	|	OG_CYear11_9 ==	1
replace	Employed84	=	1	if	OG_TwoYear12_11	==	1	|	OG_CYear12_9 ==	1
replace	Employed85	=	1	if	OG_OneYear1_11	==	1				
replace	Employed86	=	1	if	OG_OneYear2_11	==	1				
replace	Employed87	=	1	if	OG_OneYear3_11	==	1				
replace	Employed88	=	1	if	OG_OneYear4_11	==	1				
replace	Employed89	=	1	if	OG_OneYear5_11	==	1				
replace	Employed90	=	1	if	OG_OneYear6_11	==	1				
replace	Employed91	=	1	if	OG_OneYear7_11	==	1				
replace	Employed92	=	1	if	OG_OneYear8_11	==	1				
replace	Employed93	=	1	if	OG_OneYear9_11	==	1				
replace	Employed94	=	1	if	OG_OneYear10_11	==	1				
replace	Employed95	=	1	if	OG_OneYear11_11	==	1				
replace	Employed96	=	1	if	OG_OneYear12_11	==	1				
replace	Employed97	=	1	if	OG_TwoYear1_13	==	1	|	OG_CYear1_11 ==	1
replace	Employed98	=	1	if	OG_TwoYear2_13	==	1	|	OG_CYear2_11 ==	1
replace	Employed99	=	1	if	OG_TwoYear3_13	==	1	|	OG_CYear3_11 ==	1
replace	Employed100	=	1	if	OG_TwoYear4_13	==	1	|	OG_CYear4_11 ==	1
replace	Employed101	=	1	if	OG_TwoYear5_13	==	1	|	OG_CYear5_11 ==	1
replace	Employed102	=	1	if	OG_TwoYear6_13	==	1	|	OG_CYear6_11 ==	1
replace	Employed103	=	1	if	OG_TwoYear7_13	==	1	|	OG_CYear7_11 ==	1
replace	Employed104	=	1	if	OG_TwoYear8_13	==	1	|	OG_CYear8_11 ==	1
replace	Employed105	=	1	if	OG_TwoYear9_13	==	1	|	OG_CYear9_11 ==	1
replace	Employed106	=	1	if	OG_TwoYear10_13	==	1	|	OG_CYear10_11 == 1
replace	Employed107	=	1	if	OG_TwoYear11_13	==	1	|	OG_CYear11_11 == 1
replace	Employed108	=	1	if	OG_TwoYear12_13	==	1	|	OG_CYear12_11 == 1
replace	Employed109	=	1	if	OG_OneYear1_13	==	1				
replace	Employed110	=	1	if	OG_OneYear2_13	==	1				
replace	Employed111	=	1	if	OG_OneYear3_13	==	1				
replace	Employed112	=	1	if	OG_OneYear4_13	==	1				
replace	Employed113	=	1	if	OG_OneYear5_13	==	1				
replace	Employed114	=	1	if	OG_OneYear6_13	==	1				
replace	Employed115	=	1	if	OG_OneYear7_13	==	1				
replace	Employed116	=	1	if	OG_OneYear8_13	==	1				
replace	Employed117	=	1	if	OG_OneYear9_13	==	1				
replace	Employed118	=	1	if	OG_OneYear10_13	==	1				
replace	Employed119	=	1	if	OG_OneYear11_13	==	1				
replace	Employed120	=	1	if	OG_OneYear12_13	==	1				
replace	Employed121	=	1	if	OG_TwoYear1_15	==	1	|	OG_CYear1_13 ==	1
replace	Employed122	=	1	if	OG_TwoYear2_15	==	1	|	OG_CYear2_13 ==	1
replace	Employed123	=	1	if	OG_TwoYear3_15	==	1	|	OG_CYear3_13 ==	1
replace	Employed124	=	1	if	OG_TwoYear4_15	==	1	|	OG_CYear4_13 ==	1
replace	Employed125	=	1	if	OG_TwoYear5_15	==	1	|	OG_CYear5_13 ==	1
replace	Employed126	=	1	if	OG_TwoYear6_15	==	1	|	OG_CYear6_13 ==	1
replace	Employed127	=	1	if	OG_TwoYear7_15	==	1	|	OG_CYear7_13 ==	1
replace	Employed128	=	1	if	OG_TwoYear8_15	==	1	|	OG_CYear8_13 ==	1
replace	Employed129	=	1	if	OG_TwoYear9_15	==	1	|	OG_CYear9_13 ==	1
replace	Employed130	=	1	if	OG_TwoYear10_15	==	1	|	OG_CYear10_13 == 1
replace	Employed131	=	1	if	OG_TwoYear11_15	==	1	|	OG_CYear11_13 == 1
replace	Employed132	=	1	if	OG_TwoYear12_15	==	1	|	OG_CYear12_13 == 1
replace	Employed133	=	1	if	OG_OneYear1_15	==	1				
replace	Employed134	=	1	if	OG_OneYear2_15	==	1				
replace	Employed135	=	1	if	OG_OneYear3_15	==	1				
replace	Employed136	=	1	if	OG_OneYear4_15	==	1				
replace	Employed137	=	1	if	OG_OneYear5_15	==	1				
replace	Employed138	=	1	if	OG_OneYear6_15	==	1				
replace	Employed139	=	1	if	OG_OneYear7_15	==	1				
replace	Employed140	=	1	if	OG_OneYear8_15	==	1				
replace	Employed141	=	1	if	OG_OneYear9_15	==	1				
replace	Employed142	=	1	if	OG_OneYear10_15	==	1				
replace	Employed143	=	1	if	OG_OneYear11_15	==	1				
replace	Employed144	=	1	if	OG_OneYear12_15	==	1				


keep Employed* ParticipantID


*SAVING MONTHLY EMPLOYED VARIABLES
*	Saving employment at the monthly level to merge with searching and discouraged
*	and enrollment at monthly level data
cd "E:\[Anonymized]\Job Search\LMParticipation_PublicFiles\DataPull_PSID\Cleaned"
save "Employed.dta", replace


clear
clear matrix


**
**SEARCH BEHAVIOR**
**
cd "E:\[Anonymized]\Job Search\LMParticipation_PublicFiles\DataPull_PSID\Cleaned"
use "CleanedCov.dta", clear

*	SEARCHING

*GLOBAL MACRO FOR EACH MONTH UNEMPLOYED AND SEARCHING LAST YEAR
	global searchingly TA050133 TA050134 TA050135 TA050136 TA050137 TA050138 TA050139 TA050140 TA050141 TA050142 TA050143 TA050144 ///
	TA070133 TA070134 TA070135 TA070136 TA070137 TA070138 TA070139 TA070140 TA070141 TA070142 TA070143 TA070144 ///
	TA090142 TA090143 TA090144 TA090145 TA090146 TA090147 TA090148 TA090149 TA090150 TA090151 TA090152 TA090153 ///
	TA110143 TA110144 TA110145 TA110146 TA110147 TA110148 TA110149 TA110150 TA110151 TA110152 TA110153 TA110154 ///
	TA130142 TA130143 TA130144 TA130145 TA130146 TA130147 TA130148 TA130149 TA130150 TA130151 TA130152 TA130153 ///
	TA150134 TA150135 TA150136 TA150137 TA150138 TA150139 TA150140 TA150141 TA150142 TA150143 TA150144 TA150145
	
*GLOBAL MACRO FOR EACH MONTH UNEMPLOYED AND SEARCHING YEAR BEFORE LAST
	global searchingb4 TA050159 TA050160 TA050161 TA050162 TA050163 TA050164 TA050165 TA050166 TA050167 TA050168 TA050169 TA050170 ///
	TA070171 TA070172 TA070173 TA070174 TA070175 TA070176 TA070177 TA070178 TA070179 TA070180 TA070181 TA070182 ///
	TA090180 TA090181 TA090182 TA090183 TA090184 TA090185 TA090186 TA090187 TA090188 TA090189 TA090190 TA090191 ///
	TA110181 TA110182 TA110183 TA110184 TA110185 TA110186 TA110187 TA110188 TA110189 TA110190 TA110191 TA110192 ///
	TA130180 TA130181 TA130182 TA130183 TA130184 TA130185 TA130186 TA130187 TA130188 TA130189 TA130190 TA130191 ///
	TA150172 TA150173 TA150174 TA150175 TA150176 TA150177 TA150178 TA150179 TA150180 TA150181 TA150182 TA150183
	
*CLEANING SEARCHING VARIABLES
	foreach x in $searchingly $searchingb4 {
		recode `x' 9=.
		label value `x' yn
		}

*	DISCOURAGED

*GLOBAL MACRO FOR EACH MONTH UNEMPLOYED AND NOT SEARCHING LAST YEAR
	global discouragedly TA050146 TA050147 TA050148 TA050149 TA050150 TA050151 TA050152 TA050153 TA050154 TA050155 TA050156 TA050157 ///
	TA070152 TA070153 TA070154 TA070155 TA070156 TA070157 TA070158 TA070159 TA070160 TA070161 TA070162 TA070163 ///
	TA090161 TA090162 TA090163 TA090164 TA090165 TA090166 TA090167 TA090168 TA090169 TA090170 TA090171 TA090172 ///
	TA110162 TA110163 TA110164 TA110165 TA110166 TA110167 TA110168 TA110169 TA110170 TA110171 TA110172 TA110173 ///
	TA130161 TA130162 TA130163 TA130164 TA130165 TA130166 TA130167 TA130168 TA130169 TA130170 TA130171 TA130172 ///
	TA150153 TA150154 TA150155 TA150156 TA150157 TA150158 TA150159 TA150160 TA150161 TA150162 TA150163 TA150164
	
*GLOBAL MACRO FOR EACH MONTH UNEMPLOYED AND NOT SEARCHING YEAR BEFORE LAST
	global discouragedb4 TA050172 TA050173 TA050174 TA050175 TA050176 TA050177 TA050178 TA050179 TA050180 TA050181 TA050182 TA050183 ///
	TA070187 TA070188 TA070189 TA070190 TA070191 TA070192 TA070193 TA070194 TA070195 TA070196 TA070197 TA070198 ///
	TA090199 TA090200 TA090201 TA090202 TA090203 TA090204 TA090205 TA090206 TA090207 TA090208 TA090209 TA090210 ///
	TA110200 TA110201 TA110202 TA110203 TA110204 TA110205 TA110206 TA110207 TA110208 TA110209 TA110210 TA110211 ///
	TA130199 TA130200 TA130201 TA130202 TA130203 TA130204 TA130205 TA130206 TA130207 TA130208 TA130209 TA130210 ///
	TA150191 TA150192 TA150193 TA150194 TA150195 TA150196 TA150197 TA150198 TA150199 TA150200 TA150201 TA150202  

*CLEANING SEARCHING VARIABLES
	foreach x in $discouragedly $discouragedb4 {
		recode `x' 9=.
		label value `x' yn
		}
		
*KEEPING SEARCHING AND DISCOURAGED VARAIBLES
keep $searchingly $searchingb4 $discouragedly $discouragedb4 ParticipantID

		
*	MONTHLY VALUES	
		
*GENERATING 144 MONTH VARIABLES FOR SEARCHING AND DISCOURAGED BEHAVIOR
	foreach x of numlist 1/144 {
		gen Searching`x'=.
		gen Discouraged`x'=.
		}

*REPLACING SEARCHING AND DISCOURAGED VALUES
*	Searching
replace 	Searching1=TA050159
replace 	Searching2=TA050160
replace 	Searching3=TA050161
replace 	Searching4=TA050162
replace 	Searching5=TA050163
replace 	Searching6=TA050164
replace 	Searching7=TA050165
replace 	Searching8=TA050166
replace 	Searching9=TA050167
replace 	Searching10=TA050168
replace 	Searching11=TA050169
replace 	Searching12=TA050170
replace 	Searching13=TA050133
replace 	Searching14=TA050134
replace 	Searching15=TA050135
replace 	Searching16=TA050136
replace 	Searching17=TA050137
replace 	Searching18=TA050138
replace 	Searching19=TA050139
replace 	Searching20=TA050140
replace 	Searching21=TA050141
replace 	Searching22=TA050142
replace 	Searching23=TA050143
replace 	Searching24=TA050144
replace 	Searching25=TA070171
replace 	Searching26=TA070172
replace 	Searching27=TA070173
replace 	Searching28=TA070174
replace 	Searching29=TA070175
replace 	Searching30=TA070176
replace 	Searching31=TA070177
replace 	Searching32=TA070178
replace 	Searching33=TA070179
replace 	Searching34=TA070180
replace 	Searching35=TA070181
replace 	Searching36=TA070182
replace 	Searching37=TA070133
replace 	Searching38=TA070134
replace 	Searching39=TA070135
replace 	Searching40=TA070136
replace 	Searching41=TA070137
replace 	Searching42=TA070138
replace 	Searching43=TA070139
replace 	Searching44=TA070140
replace 	Searching45=TA070141
replace 	Searching46=TA070142
replace 	Searching47=TA070143
replace 	Searching48=TA070144
replace 	Searching49=TA090180
replace 	Searching50=TA090181
replace 	Searching51=TA090182
replace 	Searching52=TA090183
replace 	Searching53=TA090184
replace 	Searching54=TA090185
replace 	Searching55=TA090186
replace 	Searching56=TA090187
replace 	Searching57=TA090188
replace 	Searching58=TA090189
replace 	Searching59=TA090190
replace 	Searching60=TA090191
replace 	Searching61=TA090142
replace 	Searching62=TA090143
replace 	Searching63=TA090144
replace 	Searching64=TA090145
replace 	Searching65=TA090146
replace 	Searching66=TA090147
replace 	Searching67=TA090148
replace 	Searching68=TA090149
replace 	Searching69=TA090150
replace 	Searching70=TA090151
replace 	Searching71=TA090152
replace 	Searching72=TA090153
replace 	Searching73=TA110181
replace 	Searching74=TA110182
replace 	Searching75=TA110183
replace 	Searching76=TA110184
replace 	Searching77=TA110185
replace 	Searching78=TA110186
replace 	Searching79=TA110187
replace 	Searching80=TA110188
replace 	Searching81=TA110189
replace 	Searching82=TA110190
replace 	Searching83=TA110191
replace 	Searching84=TA110192
replace 	Searching85=TA110143
replace 	Searching86=TA110144
replace 	Searching87=TA110145
replace 	Searching88=TA110146
replace 	Searching89=TA110147
replace 	Searching90=TA110148
replace 	Searching91=TA110149
replace 	Searching92=TA110150
replace 	Searching93=TA110151
replace 	Searching94=TA110152
replace 	Searching95=TA110153
replace 	Searching96=TA110154
replace 	Searching97=TA130180
replace 	Searching98=TA130181
replace 	Searching99=TA130182
replace 	Searching100=TA130183
replace 	Searching101=TA130184
replace 	Searching102=TA130185
replace 	Searching103=TA130186
replace 	Searching104=TA130187
replace 	Searching105=TA130188
replace 	Searching106=TA130189
replace 	Searching107=TA130190
replace 	Searching108=TA130191
replace 	Searching109=TA130142
replace 	Searching110=TA130143
replace 	Searching111=TA130144
replace 	Searching112=TA130145
replace 	Searching113=TA130146
replace 	Searching114=TA130147
replace 	Searching115=TA130148
replace 	Searching116=TA130149
replace 	Searching117=TA130150
replace 	Searching118=TA130151
replace 	Searching119=TA130152
replace 	Searching120=TA130153
replace 	Searching121=TA150172
replace 	Searching122=TA150173
replace 	Searching123=TA150174
replace 	Searching124=TA150175
replace 	Searching125=TA150176
replace 	Searching126=TA150177
replace 	Searching127=TA150178
replace 	Searching128=TA150179
replace 	Searching129=TA150180
replace 	Searching130=TA150181
replace 	Searching131=TA150182
replace 	Searching132=TA150183
replace 	Searching133=TA150134
replace 	Searching134=TA150135
replace 	Searching135=TA150136
replace 	Searching136=TA150137
replace 	Searching137=TA150138
replace 	Searching138=TA150139
replace 	Searching139=TA150140
replace 	Searching140=TA150141
replace 	Searching141=TA150142
replace 	Searching142=TA150143
replace 	Searching143=TA150144
replace 	Searching144=TA150145
	
	
*	Discouraged	
replace 	Discouraged1=TA050172
replace 	Discouraged2=TA050173
replace 	Discouraged3=TA050174
replace 	Discouraged4=TA050175
replace 	Discouraged5=TA050176
replace 	Discouraged6=TA050177
replace 	Discouraged7=TA050178
replace 	Discouraged8=TA050179
replace 	Discouraged9=TA050180
replace 	Discouraged10=TA050181
replace 	Discouraged11=TA050182
replace 	Discouraged12=TA050183
replace 	Discouraged13=TA050146
replace 	Discouraged14=TA050147
replace 	Discouraged15=TA050148
replace 	Discouraged16=TA050149
replace 	Discouraged17=TA050150
replace 	Discouraged18=TA050151
replace 	Discouraged19=TA050152
replace 	Discouraged20=TA050153
replace 	Discouraged21=TA050154
replace 	Discouraged22=TA050155
replace 	Discouraged23=TA050156
replace 	Discouraged24=TA050157
replace 	Discouraged25=TA070187
replace 	Discouraged26=TA070188
replace 	Discouraged27=TA070189
replace 	Discouraged28=TA070190
replace 	Discouraged29=TA070191
replace 	Discouraged30=TA070192
replace 	Discouraged31=TA070193
replace 	Discouraged32=TA070194
replace 	Discouraged33=TA070195
replace 	Discouraged34=TA070196
replace 	Discouraged35=TA070197
replace 	Discouraged36=TA070198
replace 	Discouraged37=TA070152
replace 	Discouraged38=TA070153
replace 	Discouraged39=TA070154
replace 	Discouraged40=TA070155
replace 	Discouraged41=TA070156
replace 	Discouraged42=TA070157
replace 	Discouraged43=TA070158
replace 	Discouraged44=TA070159
replace 	Discouraged45=TA070160
replace 	Discouraged46=TA070161
replace 	Discouraged47=TA070162
replace 	Discouraged48=TA070163
replace 	Discouraged49=TA090199
replace 	Discouraged50=TA090200
replace 	Discouraged51=TA090201
replace 	Discouraged52=TA090202
replace 	Discouraged53=TA090203
replace 	Discouraged54=TA090204
replace 	Discouraged55=TA090205
replace 	Discouraged56=TA090206
replace 	Discouraged57=TA090207
replace 	Discouraged58=TA090208
replace 	Discouraged59=TA090209
replace 	Discouraged60=TA090210
replace 	Discouraged61=TA090161
replace 	Discouraged62=TA090162
replace 	Discouraged63=TA090163
replace 	Discouraged64=TA090164
replace 	Discouraged65=TA090165
replace 	Discouraged66=TA090166
replace 	Discouraged67=TA090167
replace 	Discouraged68=TA090168
replace 	Discouraged69=TA090169
replace 	Discouraged70=TA090170
replace 	Discouraged71=TA090171
replace 	Discouraged72=TA090172
replace 	Discouraged73=TA110200
replace 	Discouraged74=TA110201
replace 	Discouraged75=TA110202
replace 	Discouraged76=TA110203
replace 	Discouraged77=TA110204
replace 	Discouraged78=TA110205
replace 	Discouraged79=TA110206
replace 	Discouraged80=TA110207
replace 	Discouraged81=TA110208
replace 	Discouraged82=TA110209
replace 	Discouraged83=TA110210
replace 	Discouraged84=TA110211
replace 	Discouraged85=TA110162
replace 	Discouraged86=TA110163
replace 	Discouraged87=TA110164
replace 	Discouraged88=TA110165
replace 	Discouraged89=TA110166
replace 	Discouraged90=TA110167
replace 	Discouraged91=TA110168
replace 	Discouraged92=TA110169
replace 	Discouraged93=TA110170
replace 	Discouraged94=TA110171
replace 	Discouraged95=TA110172
replace 	Discouraged96=TA110173
replace 	Discouraged97=TA130199
replace 	Discouraged98=TA130200
replace 	Discouraged99=TA130201
replace 	Discouraged100=TA130202
replace 	Discouraged101=TA130203
replace 	Discouraged102=TA130204
replace 	Discouraged103=TA130205
replace 	Discouraged104=TA130206
replace 	Discouraged105=TA130207
replace 	Discouraged106=TA130208
replace 	Discouraged107=TA130209
replace 	Discouraged108=TA130210
replace 	Discouraged109=TA130161
replace 	Discouraged110=TA130162
replace 	Discouraged111=TA130163
replace 	Discouraged112=TA130164
replace 	Discouraged113=TA130165
replace 	Discouraged114=TA130166
replace 	Discouraged115=TA130167
replace 	Discouraged116=TA130168
replace 	Discouraged117=TA130169
replace 	Discouraged118=TA130170
replace 	Discouraged119=TA130171
replace 	Discouraged120=TA130172
replace 	Discouraged121=TA150191
replace 	Discouraged122=TA150192
replace 	Discouraged123=TA150193
replace 	Discouraged124=TA150194
replace 	Discouraged125=TA150195
replace 	Discouraged126=TA150196
replace 	Discouraged127=TA150197
replace 	Discouraged128=TA150198
replace 	Discouraged129=TA150199
replace 	Discouraged130=TA150200
replace 	Discouraged131=TA150201
replace 	Discouraged132=TA150202
replace 	Discouraged133=TA150153
replace 	Discouraged134=TA150154
replace 	Discouraged135=TA150155
replace 	Discouraged136=TA150156
replace 	Discouraged137=TA150157
replace 	Discouraged138=TA150158
replace 	Discouraged139=TA150159
replace 	Discouraged140=TA150160
replace 	Discouraged141=TA150161
replace 	Discouraged142=TA150162
replace 	Discouraged143=TA150163
replace 	Discouraged144=TA150164

keep ParticipantID Discouraged* Searching*

cd "E:\[Anonymized]\Job Search\LMParticipation_PublicFiles\DataPull_PSID\Cleaned"
save "SearchDiscouraged.dta", replace


**
**MERGING DATA**
**
cd "E:\[Anonymized]\Job Search\LMParticipation_PublicFiles\DataPull_PSID\Cleaned"
use "CleanedCov.dta", clear // covariate data

merge 1:1 ParticipantID using "SearchDiscouraged.dta" // search behavior
	drop _merge
merge 1:1 ParticipantID using "Employed.dta" // employed

drop DEMREL97 ER30000 ER32006 ER33401 ER33402 ER33403 ER33801 ER33802 ER33803 ///
ER33901 ER33902 ER33903 ER34001 ER34002 ER34003 ER34101 ER34102 ER34103 ER34201 ///
ER34202 ER34203 ER34301 ER34302 ER34303 KID97 KIDS TA050001 TA050132 TA050133 ///
TA050134 TA050135 TA050136 TA050137 TA050138 TA050139 TA050140 TA050141 TA050142 ///
TA050143 TA050144 TA050145 TA050146 TA050147 TA050148 TA050149 TA050150 TA050151 ///
TA050152 TA050153 TA050154 TA050155 TA050156 TA050157 TA050158 TA050159 TA050160 ///
TA050161 TA050162 TA050163 TA050164 TA050165 TA050166 TA050167 TA050168 TA050169 ///
TA050170 TA050171 TA050172 TA050173 TA050174 TA050175 TA050176 TA050177 TA050178 ///
TA050179 TA050180 TA050181 TA050182 TA050183 TA050185 TA050186 TA050187 TA050188 ///
TA050222 TA050224 TA050225 TA050226 TA050227 TA050228 TA050257 TA050259 TA050260 ///
TA050261 TA050262 TA050263 TA050292 TA050294 TA050295 TA050296 TA050297 TA050298 ///
TA050327 TA050329 TA050330 TA050331 TA050332 TA050333 TA050362 TA050364 TA050644 ///
TA050645 TA050646 TA050860 TA050866 TA050872 TA050951 TA050956 TA050957 TA050958 ///
TA050959 TA050960 TA050961 TA070001 TA070133 TA070134 TA070135 TA070136 TA070137 ///
TA070138 TA070139 TA070140 TA070141 TA070142 TA070143 TA070144 TA070151 TA070152 ///
TA070153 TA070154 TA070155 TA070156 TA070157 TA070158 TA070159 TA070160 TA070161 ///
TA070162 TA070163 TA070170 TA070171 TA070172 TA070173 TA070174 TA070175 TA070176 ///
TA070177 TA070178 TA070179 TA070180 TA070181 TA070182 TA070186 TA070187 TA070188 ///
TA070189 TA070190 TA070191 TA070192 TA070193 TA070194 TA070195 TA070196 TA070197 ///
TA070198 TA070203 TA070204 TA070205 TA070206 TA070256 TA070257 TA070258 TA070259 ///
TA070276 TA070277 TA070278 TA070279 TA070296 TA070297 TA070298 TA070299 TA070316 ///
TA070317 TA070318 TA070319 TA070340 TA070615 TA070616 TA070617 TA070841 TA070847 ///
TA070853 TA070932 TA070938 TA070939 TA070940 TA070941 TA070942 TA070943 TA090001 ///
TA090142 TA090143 TA090144 TA090145 TA090146 TA090147 TA090148 TA090149 TA090150 ///
TA090151 TA090152 TA090153 TA090160 TA090161 TA090162 TA090163 TA090164 TA090165 ///
TA090166 TA090167 TA090168 TA090169 TA090170 TA090171 TA090172 TA090179 TA090180 ///
TA090181 TA090182 TA090183 TA090184 TA090185 TA090186 TA090187 TA090188 TA090189 ///
TA090190 TA090191 TA090198 TA090199 TA090200 TA090201 TA090202 TA090203 TA090204 ///
TA090205 TA090206 TA090207 TA090208 TA090209 TA090210 TA090218 TA090219 TA090220 ///
TA090221 TA090273 TA090274 TA090275 TA090276 TA090293 TA090294 TA090295 TA090296 ///
TA090313 TA090314 TA090315 TA090316 TA090333 TA090334 TA090335 TA090336 TA090357 ///
TA090668 TA090669 TA090670 TA090901 TA090907 TA090913 TA090996 TA091002 TA091003 ///
TA091004 TA091005 TA091006 TA091007 TA110001 TA110143 TA110144 TA110145 TA110146 ///
TA110147 TA110148 TA110149 TA110150 TA110151 TA110152 TA110153 TA110154 TA110161 ///
TA110162 TA110163 TA110164 TA110165 TA110166 TA110167 TA110168 TA110169 TA110170 ///
TA110171 TA110172 TA110173 TA110180 TA110181 TA110182 TA110183 TA110184 TA110185 ///
TA110186 TA110187 TA110188 TA110189 TA110190 TA110191 TA110192 TA110199 TA110200 ///
TA110201 TA110202 TA110203 TA110204 TA110205 TA110206 TA110207 TA110208 TA110209 ///
TA110210 TA110211 TA110219 TA110220 TA110221 TA110222 TA110263 TA110264 TA110265 ///
TA110266 TA110283 TA110284 TA110285 TA110286 TA110303 TA110304 TA110305 TA110306 ///
TA110323 TA110324 TA110325 TA110326 TA110347 TA110689 TA110756 TA110757 TA110758 ///
TA111032 TA111038 TA111044 TA111138 TA111144 TA111145 TA111146 TA111147 TA111148 ///
TA111149 TA130001 TA130142 TA130143 TA130144 TA130145 TA130146 TA130147 TA130148 ///
TA130149 TA130150 TA130151 TA130152 TA130153 TA130160 TA130161 TA130162 TA130163 ///
TA130164 TA130165 TA130166 TA130167 TA130168 TA130169 TA130170 TA130171 TA130172 ///
TA130179 TA130180 TA130181 TA130182 TA130183 TA130184 TA130185 TA130186 TA130187 ///
TA130188 TA130189 TA130190 TA130191 TA130198 TA130199 TA130200 TA130201 TA130202 ///
TA130203 TA130204 TA130205 TA130206 TA130207 TA130208 TA130209 TA130210 TA130218 ///
TA130219 TA130220 TA130221 TA130262 TA130263 TA130264 TA130265 TA130282 TA130283 ///
TA130284 TA130285 TA130302 TA130303 TA130304 TA130305 TA130322 TA130323 TA130324 ///
TA130325 TA130346 TA130709 TA130776 TA130777 TA130778 TA131067 TA131073 TA131079 ///
TA131230 TA131235 TA131236 TA131237 TA131238 TA131239 TA131240 TA150001 TA150134 ///
TA150135 TA150136 TA150137 TA150138 TA150139 TA150140 TA150141 TA150142 TA150143 ///
TA150144 TA150145 TA150152 TA150153 TA150154 TA150155 TA150156 TA150157 TA150158 ///
TA150159 TA150160 TA150161 TA150162 TA150163 TA150164 TA150171 TA150172 TA150173 ///
TA150174 TA150175 TA150176 TA150177 TA150178 TA150179 TA150180 TA150181 TA150182 ///
TA150183 TA150190 TA150191 TA150192 TA150193 TA150194 TA150195 TA150196 TA150197 ///
TA150198 TA150199 TA150200 TA150201 TA150202 TA150210 TA150211 TA150212 TA150213 ///
TA150256 TA150257 TA150258 TA150259 TA150278 TA150279 TA150280 TA150281 TA150300 ///
TA150301 TA150302 TA150303 TA150322 TA150323 TA150324 TA150325 TA150348 TA150719 ///
TA150789 TA150790 TA150791 TA151107 TA151113 TA151119 TA151290 TA151295 TA151296 ///
TA151297 TA151298 TA151299 TA151300 co11 co13 co15 co5 co7 co9 mar11 mar13 mar15 ///
mar5 mar7 mar9 _merge EndJobFive11 EndJobFive13 EndJobFive15 EndJobFive5 ///
EndJobFive7 EndJobFive9 EndJobFour11 EndJobFour13 EndJobFour15 EndJobFour5 ///
EndJobFour7 EndJobFour9 EndJobOne11 EndJobOne13 EndJobOne15 EndJobOne5 EndJobOne7 ///
EndJobOne9 EndJobThree11 EndJobThree13 EndJobThree15 EndJobThree5 EndJobThree7 ///
EndJobThree9 EndJobTwo11 EndJobTwo13 EndJobTwo15 EndJobTwo5 EndJobTwo7 EndJobTwo9
	
		
**
**CORRECTING EMPLOYMENT DATA**
**
foreach x of num 1/24 {
	replace Employed`x'=. if TAS5!=1
}

foreach x of num 25/48 {
	replace Employed`x'=. if TAS7!=1
}

foreach x of num 49/72 {
	replace Employed`x'=. if TAS9!=1
}

foreach x of num 73/96 {
	replace Employed`x'=. if TAS11!=1
}

foreach x of num 97/120 {
	replace Employed`x'=. if TAS13!=1
}

foreach x of num 121/144 {
	replace Employed`x'=. if TAS15!=1
}


********************************************************************************
********************************************************************************
*******************  CONDENSING EMPLOYMENT AND SEARCH DATA  ********************
********************************************************************************
********************************************************************************

*2005 2 YEAR EMPLOYMENT DATA

*TWO YEAR				ONE YEAR
*------------			--------------
*JAN 03		1			JAN 04		13
*FEB 03		2			FEB 04		14
*MAR 03		3			MAR 04		15
*APR 03		4			APR 04		16
*MAY 03		5			MAY 04		17
*JUN 03		6			JUN 04		18
*JUL 03		7			JUL 04		19
*AUG 03		8			AUG 04		20
*SEP 03		9			SEP 04		21
*OCT 03		10			OCT 04		22
*NOV 03		11			NOV 04		23
*DEC 03		12			DEC 04		24

foreach x of num 3/24 {
	gen ethree_`x' = .
	gen esix_`x' = .
	gen etwelve_`x' = .
	gen sthree_`x' = .
	gen ssix_`x' = .
	gen stwelve_`x' = .
	gen dthree_`x' = .
	gen dsix_`x' = .
	gen dtwelve_`x' = .
	}

foreach x of num 3/24 {
	local j = `x'-1
	local k = `x'-2
		replace ethree_`x' = 1 if Employed`x'==1 & Employed`j'==1 & Employed`k'==1
		replace sthree_`x' = 1 if Searching`x'==1 & Searching`j'==1 & Searching`k'==1
		replace dthree_`x' = 1 if Discouraged`x'==1 & Discouraged`j'==1 & Discouraged`k'==1
	}

foreach x of num 6/24 {
	local j = `x'-1
	local k = `x'-2
	local l = `x'-3
	local m = `x'-4
	local n = `x'-5
		replace esix_`x' = 1 if Employed`x'==1 & Employed`j'==1 & Employed`k'==1 ///
			& Employed`l'==1 & Employed`m'==1 & Employed`n'==1
		replace ssix_`x' = 1 if Searching`x'==1 & Searching`j'==1 & Searching`k'==1 ///
			& Searching`l'==1 & Searching`m'==1 & Searching`n'==1
		replace dsix_`x' = 1 if Discouraged`x'==1 & Discouraged`j'==1 & Discouraged`k'==1 ///
			& Discouraged`l'==1 & Discouraged`m'==1 & Discouraged`n'==1
	}

foreach x of num 12/24 {
	local j = `x'-1
	local k = `x'-2
	local l = `x'-3
	local m = `x'-4
	local n = `x'-5
	local o = `x'-6
	local p = `x'-7
	local q = `x'-8
	local r = `x'-9
	local s = `x'-10
	local t = `x'-11
		replace etwelve_`x' = 1 if Employed`x'==1 & Employed`j'==1 & Employed`k'==1 ///
			& Employed`l'==1 & Employed`m'==1 & Employed`n'==1 & Employed`o'==1 ///
			& Employed`p'==1 & Employed`q'==1 & Employed`r'==1 & Employed`s'==1 & Employed`t'==1
		replace stwelve_`x' = 1 if Searching`x'==1 & Searching`j'==1 & Searching`k'==1 ///
			& Searching`l'==1 & Searching`m'==1 & Searching`n'==1 & Searching`o'==1 ///
			& Searching`p'==1 & Searching`q'==1 & Searching`r'==1 & Searching`s'==1 & Searching`t'==1
		replace dtwelve_`x' = 1 if Discouraged`x'==1 & Discouraged`j'==1 & Discouraged`k'==1 ///
			& Discouraged`l'==1 & Discouraged`m'==1 & Discouraged`n'==1 & Discouraged`o'==1 ///
			& Discouraged`p'==1 & Discouraged`q'==1 & Discouraged`r'==1 & Discouraged`s'==1 & Discouraged`t'==1
	}


*2007 2 YEAR EMPLOYMENT DATA

*TWO YEAR				ONE YEAR
*------------			--------------
*JAN 05		25			JAN 06		37
*FEB 05		26			FEB 06		38
*MAR 05		27			MAR 06		39
*APR 05		28			APR 06		40
*MAY 05		29			MAY 06		41
*JUN 05		30			JUN 06		42
*JUL 05		31			JUL 06		43
*AUG 05		32			AUG 06		44
*SEP 05		33			SEP 06		45
*OCT 05		34			OCT 06		46
*NOV 05		35			NOV 06		47
*DEC 05		36			DEC 06		48

foreach x of num 27/48 {
	gen ethree_`x' = .
	gen esix_`x' = .
	gen etwelve_`x' = .
	gen sthree_`x' = .
	gen ssix_`x' = .
	gen stwelve_`x' = .
	gen dthree_`x' = .
	gen dsix_`x' = .
	gen dtwelve_`x' = .
	}

foreach x of num 27/48 {
	local j = `x'-1
	local k = `x'-2
		replace ethree_`x' = 1 if Employed`x'==1 & Employed`j'==1 & Employed`k'==1
		replace sthree_`x' = 1 if Searching`x'==1 & Searching`j'==1 & Searching`k'==1
		replace dthree_`x' = 1 if Discouraged`x'==1 & Discouraged`j'==1 & Discouraged`k'==1
	}

foreach x of num 30/48 {
	local j = `x'-1
	local k = `x'-2
	local l = `x'-3
	local m = `x'-4
	local n = `x'-5
		replace esix_`x' = 1 if Employed`x'==1 & Employed`j'==1 & Employed`k'==1 ///
			& Employed`l'==1 & Employed`m'==1 & Employed`n'==1
		replace ssix_`x' = 1 if Searching`x'==1 & Searching`j'==1 & Searching`k'==1 ///
			& Searching`l'==1 & Searching`m'==1 & Searching`n'==1
		replace dsix_`x' = 1 if Discouraged`x'==1 & Discouraged`j'==1 & Discouraged`k'==1 ///
			& Discouraged`l'==1 & Discouraged`m'==1 & Discouraged`n'==1
	}

foreach x of num 36/48 {
	local j = `x'-1
	local k = `x'-2
	local l = `x'-3
	local m = `x'-4
	local n = `x'-5
	local o = `x'-6
	local p = `x'-7
	local q = `x'-8
	local r = `x'-9
	local s = `x'-10
	local t = `x'-11
		replace etwelve_`x' = 1 if Employed`x'==1 & Employed`j'==1 & Employed`k'==1 ///
			& Employed`l'==1 & Employed`m'==1 & Employed`n'==1 & Employed`o'==1 ///
			& Employed`p'==1 & Employed`q'==1 & Employed`r'==1 & Employed`s'==1 & Employed`t'==1
		replace stwelve_`x' = 1 if Searching`x'==1 & Searching`j'==1 & Searching`k'==1 ///
			& Searching`l'==1 & Searching`m'==1 & Searching`n'==1 & Searching`o'==1 ///
			& Searching`p'==1 & Searching`q'==1 & Searching`r'==1 & Searching`s'==1 & Searching`t'==1
		replace dtwelve_`x' = 1 if Discouraged`x'==1 & Discouraged`j'==1 & Discouraged`k'==1 ///
			& Discouraged`l'==1 & Discouraged`m'==1 & Discouraged`n'==1 & Discouraged`o'==1 ///
			& Discouraged`p'==1 & Discouraged`q'==1 & Discouraged`r'==1 & Discouraged`s'==1 & Discouraged`t'==1
	}

*2009 2 YEAR EMPLOYMENT DATA

*TWO YEAR				ONE YEAR
*------------			--------------
*JAN 07		49			JAN 08		61
*FEB 07		50			FEB 08		62
*MAR 07		51			MAR 08		63
*APR 07		52			APR 08		64
*MAY 07		53			MAY 08		65
*JUN 07		54			JUN 08		66
*JUL 07		55			JUL 08		67
*AUG 07		56			AUG 08		68
*SEP 07		57			SEP 08		69
*OCT 07		58			OCT 08		70
*NOV 07		59			NOV 08		71
*DEC 07		60			DEC 08		72

foreach x of num 51/72 {
	gen ethree_`x' = .
	gen esix_`x' = .
	gen etwelve_`x' = .
	gen sthree_`x' = .
	gen ssix_`x' = .
	gen stwelve_`x' = .
	gen dthree_`x' = .
	gen dsix_`x' = .
	gen dtwelve_`x' = .
	}

foreach x of num 51/72 {
	local j = `x'-1
	local k = `x'-2
		replace ethree_`x' = 1 if Employed`x'==1 & Employed`j'==1 & Employed`k'==1
		replace sthree_`x' = 1 if Searching`x'==1 & Searching`j'==1 & Searching`k'==1
		replace dthree_`x' = 1 if Discouraged`x'==1 & Discouraged`j'==1 & Discouraged`k'==1
	}

foreach x of num 54/72 {
	local j = `x'-1
	local k = `x'-2
	local l = `x'-3
	local m = `x'-4
	local n = `x'-5
		replace esix_`x' = 1 if Employed`x'==1 & Employed`j'==1 & Employed`k'==1 ///
			& Employed`l'==1 & Employed`m'==1 & Employed`n'==1
		replace ssix_`x' = 1 if Searching`x'==1 & Searching`j'==1 & Searching`k'==1 ///
			& Searching`l'==1 & Searching`m'==1 & Searching`n'==1
		replace dsix_`x' = 1 if Discouraged`x'==1 & Discouraged`j'==1 & Discouraged`k'==1 ///
			& Discouraged`l'==1 & Discouraged`m'==1 & Discouraged`n'==1
	}

foreach x of num 60/72 {
	local j = `x'-1
	local k = `x'-2
	local l = `x'-3
	local m = `x'-4
	local n = `x'-5
	local o = `x'-6
	local p = `x'-7
	local q = `x'-8
	local r = `x'-9
	local s = `x'-10
	local t = `x'-11
		replace etwelve_`x' = 1 if Employed`x'==1 & Employed`j'==1 & Employed`k'==1 ///
			& Employed`l'==1 & Employed`m'==1 & Employed`n'==1 & Employed`o'==1 ///
			& Employed`p'==1 & Employed`q'==1 & Employed`r'==1 & Employed`s'==1 & Employed`t'==1
		replace stwelve_`x' = 1 if Searching`x'==1 & Searching`j'==1 & Searching`k'==1 ///
			& Searching`l'==1 & Searching`m'==1 & Searching`n'==1 & Searching`o'==1 ///
			& Searching`p'==1 & Searching`q'==1 & Searching`r'==1 & Searching`s'==1 & Searching`t'==1
		replace dtwelve_`x' = 1 if Discouraged`x'==1 & Discouraged`j'==1 & Discouraged`k'==1 ///
			& Discouraged`l'==1 & Discouraged`m'==1 & Discouraged`n'==1 & Discouraged`o'==1 ///
			& Discouraged`p'==1 & Discouraged`q'==1 & Discouraged`r'==1 & Discouraged`s'==1 & Discouraged`t'==1
	}

*2011 2 YEAR EMPLOYMENT DATA

*TWO YEAR				ONE YEAR
*------------			--------------
*JAN 09		73			JAN 10		85
*FEB 09		74			FEB 10		86
*MAR 09		75			MAR 10		87
*APR 09		76			APR 10		88
*MAY 09		77			MAY 10		89
*JUN 09		78			JUN 10		90
*JUL 09		79			JUL 10		91
*AUG 09		80			AUG 10		92
*SEP 09		81			SEP 10		93
*OCT 09		82			OCT 10		94
*NOV 09		83			NOV 10		95
*DEC 09		84			DEC 10		96

foreach x of num 75/96 {
	gen ethree_`x' = .
	gen esix_`x' = .
	gen etwelve_`x' = .
	gen sthree_`x' = .
	gen ssix_`x' = .
	gen stwelve_`x' = .
	gen dthree_`x' = .
	gen dsix_`x' = .
	gen dtwelve_`x' = .
	}

foreach x of num 75/96 {
	local j = `x'-1
	local k = `x'-2
		replace ethree_`x' = 1 if Employed`x'==1 & Employed`j'==1 & Employed`k'==1
		replace sthree_`x' = 1 if Searching`x'==1 & Searching`j'==1 & Searching`k'==1
		replace dthree_`x' = 1 if Discouraged`x'==1 & Discouraged`j'==1 & Discouraged`k'==1
	}

foreach x of num 78/96 {
	local j = `x'-1
	local k = `x'-2
	local l = `x'-3
	local m = `x'-4
	local n = `x'-5
		replace esix_`x' = 1 if Employed`x'==1 & Employed`j'==1 & Employed`k'==1 ///
			& Employed`l'==1 & Employed`m'==1 & Employed`n'==1
		replace ssix_`x' = 1 if Searching`x'==1 & Searching`j'==1 & Searching`k'==1 ///
			& Searching`l'==1 & Searching`m'==1 & Searching`n'==1
		replace dsix_`x' = 1 if Discouraged`x'==1 & Discouraged`j'==1 & Discouraged`k'==1 ///
			& Discouraged`l'==1 & Discouraged`m'==1 & Discouraged`n'==1
	}

foreach x of num 84/96 {
	local j = `x'-1
	local k = `x'-2
	local l = `x'-3
	local m = `x'-4
	local n = `x'-5
	local o = `x'-6
	local p = `x'-7
	local q = `x'-8
	local r = `x'-9
	local s = `x'-10
	local t = `x'-11
		replace etwelve_`x' = 1 if Employed`x'==1 & Employed`j'==1 & Employed`k'==1 ///
			& Employed`l'==1 & Employed`m'==1 & Employed`n'==1 & Employed`o'==1 ///
			& Employed`p'==1 & Employed`q'==1 & Employed`r'==1 & Employed`s'==1 & Employed`t'==1
		replace stwelve_`x' = 1 if Searching`x'==1 & Searching`j'==1 & Searching`k'==1 ///
			& Searching`l'==1 & Searching`m'==1 & Searching`n'==1 & Searching`o'==1 ///
			& Searching`p'==1 & Searching`q'==1 & Searching`r'==1 & Searching`s'==1 & Searching`t'==1
		replace dtwelve_`x' = 1 if Discouraged`x'==1 & Discouraged`j'==1 & Discouraged`k'==1 ///
			& Discouraged`l'==1 & Discouraged`m'==1 & Discouraged`n'==1 & Discouraged`o'==1 ///
			& Discouraged`p'==1 & Discouraged`q'==1 & Discouraged`r'==1 & Discouraged`s'==1 & Discouraged`t'==1
	}

*2013 2 YEAR EMPLOYMENT DATA

*TWO YEAR				ONE YEAR
*------------			--------------
*JAN 11		97			JAN 12		109
*FEB 11		98			FEB 12		110
*MAR 11		99			MAR 12		111
*APR 11		100			APR 12		112
*MAY 11		101			MAY 12		113
*JUN 11		102			JUN 12		114
*JUL 11		103			JUL 12		115
*AUG 11		104			AUG 12		116
*SEP 11		105			SEP 12		117
*OCT 11		106			OCT 12		118
*NOV 11		107			NOV 12		119
*DEC 11		108			DEC 12		120

foreach x of num 99/120 {
	gen ethree_`x' = .
	gen esix_`x' = .
	gen etwelve_`x' = .
	gen sthree_`x' = .
	gen ssix_`x' = .
	gen stwelve_`x' = .
	gen dthree_`x' = .
	gen dsix_`x' = .
	gen dtwelve_`x' = .
	}

foreach x of num 99/120 {
	local j = `x'-1
	local k = `x'-2
		replace ethree_`x' = 1 if Employed`x'==1 & Employed`j'==1 & Employed`k'==1
		replace sthree_`x' = 1 if Searching`x'==1 & Searching`j'==1 & Searching`k'==1
		replace dthree_`x' = 1 if Discouraged`x'==1 & Discouraged`j'==1 & Discouraged`k'==1
	}

foreach x of num 102/120 {
	local j = `x'-1
	local k = `x'-2
	local l = `x'-3
	local m = `x'-4
	local n = `x'-5
		replace esix_`x' = 1 if Employed`x'==1 & Employed`j'==1 & Employed`k'==1 ///
			& Employed`l'==1 & Employed`m'==1 & Employed`n'==1
		replace ssix_`x' = 1 if Searching`x'==1 & Searching`j'==1 & Searching`k'==1 ///
			& Searching`l'==1 & Searching`m'==1 & Searching`n'==1
		replace dsix_`x' = 1 if Discouraged`x'==1 & Discouraged`j'==1 & Discouraged`k'==1 ///
			& Discouraged`l'==1 & Discouraged`m'==1 & Discouraged`n'==1
	}

foreach x of num 108/120 {
	local j = `x'-1
	local k = `x'-2
	local l = `x'-3
	local m = `x'-4
	local n = `x'-5
	local o = `x'-6
	local p = `x'-7
	local q = `x'-8
	local r = `x'-9
	local s = `x'-10
	local t = `x'-11
		replace etwelve_`x' = 1 if Employed`x'==1 & Employed`j'==1 & Employed`k'==1 ///
			& Employed`l'==1 & Employed`m'==1 & Employed`n'==1 & Employed`o'==1 ///
			& Employed`p'==1 & Employed`q'==1 & Employed`r'==1 & Employed`s'==1 & Employed`t'==1
		replace stwelve_`x' = 1 if Searching`x'==1 & Searching`j'==1 & Searching`k'==1 ///
			& Searching`l'==1 & Searching`m'==1 & Searching`n'==1 & Searching`o'==1 ///
			& Searching`p'==1 & Searching`q'==1 & Searching`r'==1 & Searching`s'==1 & Searching`t'==1
		replace dtwelve_`x' = 1 if Discouraged`x'==1 & Discouraged`j'==1 & Discouraged`k'==1 ///
			& Discouraged`l'==1 & Discouraged`m'==1 & Discouraged`n'==1 & Discouraged`o'==1 ///
			& Discouraged`p'==1 & Discouraged`q'==1 & Discouraged`r'==1 & Discouraged`s'==1 & Discouraged`t'==1
	}

*2015 2 YEAR EMPLOYMENT DATA

*TWO YEAR				ONE YEAR
*------------			--------------
*JAN 13		121			JAN 14		133
*FEB 13		122			FEB 14		134
*MAR 13		123			MAR 14		135
*APR 13		124			APR 14		136
*MAY 13		125			MAY 14		137
*JUN 13		126			JUN 14		138
*JUL 13		127			JUL 14		139
*AUG 13		128			AUG 14		140
*SEP 13		129			SEP 14		141
*OCT 13		130			OCT 14		142
*NOV 13		131			NOV 14		143
*DEC 13		132			DEC 14		144


foreach x of num 123/144 {
	gen ethree_`x' = .
	gen esix_`x' = .
	gen etwelve_`x' = .
	gen sthree_`x' = .
	gen ssix_`x' = .
	gen stwelve_`x' = .
	gen dthree_`x' = .
	gen dsix_`x' = .
	gen dtwelve_`x' = .
	}

foreach x of num 123/144 {
	local j = `x'-1
	local k = `x'-2
		replace ethree_`x' = 1 if Employed`x'==1 & Employed`j'==1 & Employed`k'==1
		replace sthree_`x' = 1 if Searching`x'==1 & Searching`j'==1 & Searching`k'==1
		replace dthree_`x' = 1 if Discouraged`x'==1 & Discouraged`j'==1 & Discouraged`k'==1
	}

foreach x of num 126/144 {
	local j = `x'-1
	local k = `x'-2
	local l = `x'-3
	local m = `x'-4
	local n = `x'-5
		replace esix_`x' = 1 if Employed`x'==1 & Employed`j'==1 & Employed`k'==1 ///
			& Employed`l'==1 & Employed`m'==1 & Employed`n'==1
		replace ssix_`x' = 1 if Searching`x'==1 & Searching`j'==1 & Searching`k'==1 ///
			& Searching`l'==1 & Searching`m'==1 & Searching`n'==1
		replace dsix_`x' = 1 if Discouraged`x'==1 & Discouraged`j'==1 & Discouraged`k'==1 ///
			& Discouraged`l'==1 & Discouraged`m'==1 & Discouraged`n'==1
	}

foreach x of num 132/144 {
	local j = `x'-1
	local k = `x'-2
	local l = `x'-3
	local m = `x'-4
	local n = `x'-5
	local o = `x'-6
	local p = `x'-7
	local q = `x'-8
	local r = `x'-9
	local s = `x'-10
	local t = `x'-11
		replace etwelve_`x' = 1 if Employed`x'==1 & Employed`j'==1 & Employed`k'==1 ///
			& Employed`l'==1 & Employed`m'==1 & Employed`n'==1 & Employed`o'==1 ///
			& Employed`p'==1 & Employed`q'==1 & Employed`r'==1 & Employed`s'==1 & Employed`t'==1
		replace stwelve_`x' = 1 if Searching`x'==1 & Searching`j'==1 & Searching`k'==1 ///
			& Searching`l'==1 & Searching`m'==1 & Searching`n'==1 & Searching`o'==1 ///
			& Searching`p'==1 & Searching`q'==1 & Searching`r'==1 & Searching`s'==1 & Searching`t'==1
		replace dtwelve_`x' = 1 if Discouraged`x'==1 & Discouraged`j'==1 & Discouraged`k'==1 ///
			& Discouraged`l'==1 & Discouraged`m'==1 & Discouraged`n'==1 & Discouraged`o'==1 ///
			& Discouraged`p'==1 & Discouraged`q'==1 & Discouraged`r'==1 & Discouraged`s'==1 & Discouraged`t'==1
	}

	
**
**CONDENSING TO THE wave LEVEL**
**
foreach x in 5 7 9 11 13 15 {
	foreach y in Employed Searching Discgd {
		foreach z in Three Six Twelve {
			gen `y'_`z'`x' = .
		}
	}
}

foreach x of num 3/24 {
	replace Employed_Three5 = 1 if ethree_`x'==1
	replace Employed_Six5 = 1 if esix_`x'==1
	replace Employed_Twelve5 = 1 if etwelve_`x'==1
	replace Searching_Three5 = 1 if sthree_`x'==1
	replace Searching_Six5 = 1 if ssix_`x'==1
	replace Searching_Twelve5 = 1 if stwelve_`x'==1
	replace Discgd_Three5 = 1 if dthree_`x'==1
	replace Discgd_Six5 = 1 if dsix_`x'==1
	replace Discgd_Twelve5 = 1 if dtwelve_`x'==1
}

egen Employed_Total5 = rowtotal(Employed1 Employed2 Employed3 Employed4 Employed5 Employed6 Employed7 Employed8 Employed9 Employed10 Employed11 Employed12 Employed13 Employed14 Employed15 Employed16 Employed17 Employed18 Employed19 Employed20 Employed21 Employed22 Employed23 Employed24)
egen Searching_Total5 = rowtotal(Searching1 Searching2 Searching3 Searching4 Searching5 Searching6 Searching7 Searching8 Searching9 Searching10 Searching11 Searching12 Searching13 Searching14 Searching15 Searching16 Searching17 Searching18 Searching19 Searching20 Searching21 Searching22 Searching23 Searching24)
egen Discgd_Total5 = rowtotal(Discouraged1 Discouraged2 Discouraged3 Discouraged4 Discouraged5 Discouraged6 Discouraged7 Discouraged8 Discouraged9 Discouraged10 Discouraged11 Discouraged12 Discouraged13 Discouraged14 Discouraged15 Discouraged16 Discouraged17 Discouraged18 Discouraged19 Discouraged20 Discouraged21 Discouraged22 Discouraged23 Discouraged24)

foreach x of num 27/48 {
	replace Employed_Three7 = 1 if ethree_`x'==1
	replace Employed_Six7 = 1 if esix_`x'==1
	replace Employed_Twelve7 = 1 if etwelve_`x'==1
	replace Searching_Three7 = 1 if sthree_`x'==1
	replace Searching_Six7 = 1 if ssix_`x'==1
	replace Searching_Twelve7 = 1 if stwelve_`x'==1
	replace Discgd_Three7 = 1 if dthree_`x'==1
	replace Discgd_Six7 = 1 if dsix_`x'==1
	replace Discgd_Twelve7 = 1 if dtwelve_`x'==1
}

egen Employed_Total7 = rowtotal(Employed25 Employed26 Employed27 Employed28 Employed29 Employed30 Employed31 Employed32 Employed33 Employed34 Employed35 Employed36 Employed37 Employed38 Employed39 Employed40 Employed41 Employed42 Employed43 Employed44 Employed45 Employed46 Employed47 Employed48)
egen Searching_Total7 = rowtotal(Searching25 Searching26 Searching27 Searching28 Searching29 Searching30 Searching31 Searching32 Searching33 Searching34 Searching35 Searching36 Searching37 Searching38 Searching39 Searching40 Searching41 Searching42 Searching43 Searching44 Searching45 Searching46 Searching47 Searching48)
egen Discgd_Total7 = rowtotal(Discouraged25 Discouraged26 Discouraged27 Discouraged28 Discouraged29 Discouraged30 Discouraged31 Discouraged32 Discouraged33 Discouraged34 Discouraged35 Discouraged36 Discouraged37 Discouraged38 Discouraged39 Discouraged40 Discouraged41 Discouraged42 Discouraged43 Discouraged44 Discouraged45 Discouraged46 Discouraged47 Discouraged48)

foreach x of num 51/72 {
	replace Employed_Three9 = 1 if ethree_`x'==1
	replace Employed_Six9 = 1 if esix_`x'==1
	replace Employed_Twelve9 = 1 if etwelve_`x'==1
	replace Searching_Three9 = 1 if sthree_`x'==1
	replace Searching_Six9 = 1 if ssix_`x'==1
	replace Searching_Twelve9 = 1 if stwelve_`x'==1
	replace Discgd_Three9 = 1 if dthree_`x'==1
	replace Discgd_Six9 = 1 if dsix_`x'==1
	replace Discgd_Twelve9 = 1 if dtwelve_`x'==1 
}

egen Employed_Total9 = rowtotal(Employed49 Employed50 Employed51 Employed52 Employed53 Employed54 Employed55 Employed56 Employed57 Employed58 Employed59 Employed60 Employed61 Employed62 Employed63 Employed64 Employed65 Employed66 Employed67 Employed68 Employed69 Employed70 Employed71 Employed72)
egen Searching_Total9 = rowtotal(Searching49 Searching50 Searching51 Searching52 Searching53 Searching54 Searching55 Searching56 Searching57 Searching58 Searching59 Searching60 Searching61 Searching62 Searching63 Searching64 Searching65 Searching66 Searching67 Searching68 Searching69 Searching70 Searching71 Searching72)
egen Discgd_Total9 = rowtotal(Discouraged49 Discouraged50 Discouraged51 Discouraged52 Discouraged53 Discouraged54 Discouraged55 Discouraged56 Discouraged57 Discouraged58 Discouraged59 Discouraged60 Discouraged61 Discouraged62 Discouraged63 Discouraged64 Discouraged65 Discouraged66 Discouraged67 Discouraged68 Discouraged69 Discouraged70 Discouraged71 Discouraged72)

foreach x of num 75/96 {
	replace Employed_Three11 = 1 if ethree_`x'==1
	replace Employed_Six11 = 1 if esix_`x'==1
	replace Employed_Twelve11 = 1 if etwelve_`x'==1
	replace Searching_Three11 = 1 if sthree_`x'==1
	replace Searching_Six11 = 1 if ssix_`x'==1
	replace Searching_Twelve11 = 1 if stwelve_`x'==1
	replace Discgd_Three11 = 1 if dthree_`x'==1
	replace Discgd_Six11 = 1 if dsix_`x'==1
	replace Discgd_Twelve11 = 1 if dtwelve_`x'==1
}

egen Employed_Total11 = rowtotal(Employed73 Employed74 Employed75 Employed76 Employed77 Employed78 Employed79 Employed80 Employed81 Employed82 Employed83 Employed84 Employed85 Employed86 Employed87 Employed88 Employed89 Employed90 Employed91 Employed92 Employed93 Employed94 Employed95 Employed96)
egen Searching_Total11 = rowtotal(Searching73 Searching74 Searching75 Searching76 Searching77 Searching78 Searching79 Searching80 Searching81 Searching82 Searching83 Searching84 Searching85 Searching86 Searching87 Searching88 Searching89 Searching90 Searching91 Searching92 Searching93 Searching94 Searching95 Searching96)
egen Discgd_Total11 = rowtotal(Discouraged73 Discouraged74 Discouraged75 Discouraged76 Discouraged77 Discouraged78 Discouraged79 Discouraged80 Discouraged81 Discouraged82 Discouraged83 Discouraged84 Discouraged85 Discouraged86 Discouraged87 Discouraged88 Discouraged89 Discouraged90 Discouraged91 Discouraged92 Discouraged93 Discouraged94 Discouraged95 Discouraged96)

foreach x of num 99/120 {
	replace Employed_Three13 = 1 if ethree_`x'==1
	replace Employed_Six13 = 1 if esix_`x'==1
	replace Employed_Twelve13 = 1 if etwelve_`x'==1
	replace Searching_Three13 = 1 if sthree_`x'==1
	replace Searching_Six13 = 1 if ssix_`x'==1
	replace Searching_Twelve13 = 1 if stwelve_`x'==1
	replace Discgd_Three13 = 1 if dthree_`x'==1
	replace Discgd_Six13 = 1 if dsix_`x'==1
	replace Discgd_Twelve13 = 1 if dtwelve_`x'==1
}

egen Employed_Total13 = rowtotal(Employed97 Employed98 Employed99 Employed100 Employed101 Employed102 Employed103 Employed104 Employed105 Employed106 Employed107 Employed108 Employed109 Employed110 Employed111 Employed112 Employed113 Employed114 Employed115 Employed116 Employed117 Employed118 Employed119 Employed120)
egen Searching_Total13 = rowtotal(Searching97 Searching98 Searching99 Searching100 Searching101 Searching102 Searching103 Searching104 Searching105 Searching106 Searching107 Searching108 Searching109 Searching110 Searching111 Searching112 Searching113 Searching114 Searching115 Searching116 Searching117 Searching118 Searching119 Searching120)
egen Discgd_Total13 = rowtotal(Discouraged97 Discouraged98 Discouraged99 Discouraged100 Discouraged101 Discouraged102 Discouraged103 Discouraged104 Discouraged105 Discouraged106 Discouraged107 Discouraged108 Discouraged109 Discouraged110 Discouraged111 Discouraged112 Discouraged113 Discouraged114 Discouraged115 Discouraged116 Discouraged117 Discouraged118 Discouraged119 Discouraged120)

foreach x of num 123/144 {
	replace Employed_Three15 = 1 if ethree_`x'==1
	replace Employed_Six15 = 1 if esix_`x'==1
	replace Employed_Twelve15 = 1 if etwelve_`x'==1
	replace Searching_Three15 = 1 if sthree_`x'==1
	replace Searching_Six15 = 1 if ssix_`x'==1
	replace Searching_Twelve15 = 1 if stwelve_`x'==1
	replace Discgd_Three15 = 1 if dthree_`x'==1
	replace Discgd_Six15 = 1 if dsix_`x'==1
	replace Discgd_Twelve15 = 1 if dtwelve_`x'==1
}

egen Employed_Total15 = rowtotal(Employed121 Employed122 Employed123 Employed124 Employed125 Employed126 Employed127 Employed128 Employed129 Employed130 Employed131 Employed132 Employed133 Employed134 Employed135 Employed136 Employed137 Employed138 Employed139 Employed140 Employed141 Employed142 Employed143 Employed144)
egen Searching_Total15 = rowtotal(Searching121 Searching122 Searching123 Searching124 Searching125 Searching126 Searching127 Searching128 Searching129 Searching130 Searching131 Searching132 Searching133 Searching134 Searching135 Searching136 Searching137 Searching138 Searching139 Searching140 Searching141 Searching142 Searching143 Searching144)
egen Discgd_Total15 = rowtotal(Discouraged121 Discouraged122 Discouraged123 Discouraged124 Discouraged125 Discouraged126 Discouraged127 Discouraged128 Discouraged129 Discouraged130 Discouraged131 Discouraged132 Discouraged133 Discouraged134 Discouraged135 Discouraged136 Discouraged137 Discouraged138 Discouraged139 Discouraged140 Discouraged141 Discouraged142 Discouraged143 Discouraged144)


*	Correcting total state values 
foreach x in 5 7 9 11 13 15 {
	foreach y in Employed_ Searching_ Discgd_ {
		replace `y'Total`x' = . if TAS`x'!=1
	}
}


*	Filling zero values for valid waves

foreach x in 5 7 9 11 13 15 {
	foreach y in Employed_ Searching_ Discgd_ {
		foreach z in Three Six Twelve Total {
			replace `y'`z'`x' = 0 if `y'`z'`x'==. & TAS`x'==1
		}
	}
}


*	Summative stats 
	global Employ Employed_Three5 Employed_Six5 Employed_Twelve5 Employed_Three7 ///
		Employed_Six7 Employed_Twelve7 Employed_Three9 Employed_Six9 Employed_Twelve9 ///
		Employed_Three11 Employed_Six11 Employed_Twelve11 Employed_Three13 ///
		Employed_Six13 Employed_Twelve13 Employed_Three15 Employed_Six15 ///
		Employed_Twelve15
	global Search Searching_Three5 Searching_Six5 Searching_Twelve5 Searching_Three7 ///
		Searching_Six7 Searching_Twelve7 Searching_Three9 Searching_Six9 ///
		Searching_Twelve9 Searching_Three11 Searching_Six11 Searching_Twelve11 ///
		Searching_Three13 Searching_Six13 Searching_Twelve13 Searching_Three15 ///
		Searching_Six15 Searching_Twelve15
	global Discgd Discgd_Three5 Discgd_Six5 Discgd_Twelve5 Discgd_Three7 Discgd_Six7 ///
		Discgd_Twelve7 Discgd_Three9 Discgd_Six9 Discgd_Twelve9 Discgd_Three11 ///
		Discgd_Six11 Discgd_Twelve11 Discgd_Three13 Discgd_Six13 Discgd_Twelve13 ///
		Discgd_Three15 Discgd_Six15 Discgd_Twelve15
		
	sum $Employ $Search $Discgd

/*
table, statistic(mean $Employ $Search $Discgd)

foreach x in ArrestEver ProbationEver JailEver {
	foreach y in 5 7 9 11 13 15 {
		foreach a in Employed_ Searching_ Discgd_ {
			foreach b in Three Six Twelve {
				table `x'`y', c(mean `a'`b'`y')	
			}
		}
	}
}
*/


**
**PRESENCE OF TRANSITIONS OUT OF SEARCH
**

foreach x of numlist 1/144 {
	gen SearchtoEmploy`x' = .
	gen SearchtoOOLF`x' = .
}

foreach x of numlist 2/24 { // 2005
	local j = `x' - 1
	replace SearchtoEmploy`x' = 1 if Searching`j' == 1 & Employed`x' == 1 & Employed`j' != 1
	replace SearchtoOOLF`x' = 1 if Searching`j' == 1 & Discouraged`x' == 1 & Employed`j' != 1	
}

	egen TransitionEmploy5 = rowmax(SearchtoEmploy1 SearchtoEmploy2 SearchtoEmploy3 SearchtoEmploy4 SearchtoEmploy5 SearchtoEmploy6 SearchtoEmploy7 SearchtoEmploy8 SearchtoEmploy9 SearchtoEmploy10 SearchtoEmploy11 SearchtoEmploy12 SearchtoEmploy13 SearchtoEmploy14 SearchtoEmploy15 SearchtoEmploy16 SearchtoEmploy17 SearchtoEmploy18 SearchtoEmploy19 SearchtoEmploy20 SearchtoEmploy21 SearchtoEmploy22 SearchtoEmploy23 SearchtoEmploy24)
	egen TransitionOOLF5 = rowmax(SearchtoOOLF1 SearchtoOOLF2 SearchtoOOLF3 SearchtoOOLF4 SearchtoOOLF5 SearchtoOOLF6 SearchtoOOLF7 SearchtoOOLF8 SearchtoOOLF9 SearchtoOOLF10 SearchtoOOLF11 SearchtoOOLF12 SearchtoOOLF13 SearchtoOOLF14 SearchtoOOLF15 SearchtoOOLF16 SearchtoOOLF17 SearchtoOOLF18 SearchtoOOLF19 SearchtoOOLF20 SearchtoOOLF21 SearchtoOOLF22 SearchtoOOLF23 SearchtoOOLF24)
	
foreach x of numlist 26/48 { // 2007
	local j = `x' - 1
	replace SearchtoEmploy`x' = 1 if Searching`j' == 1 & Employed`x' == 1 & Employed`j' != 1
	replace SearchtoOOLF`x' = 1 if Searching`j' == 1 & Discouraged`x' == 1 & Employed`j' != 1	
}

	egen TransitionEmploy7 = rowmax(SearchtoEmploy25 SearchtoEmploy26 SearchtoEmploy27 SearchtoEmploy28 SearchtoEmploy29 SearchtoEmploy30 SearchtoEmploy31 SearchtoEmploy32 SearchtoEmploy33 SearchtoEmploy34 SearchtoEmploy35 SearchtoEmploy36 SearchtoEmploy37 SearchtoEmploy38 SearchtoEmploy39 SearchtoEmploy40 SearchtoEmploy41 SearchtoEmploy42 SearchtoEmploy43 SearchtoEmploy44 SearchtoEmploy45 SearchtoEmploy46 SearchtoEmploy47 SearchtoEmploy48)
	egen TransitionOOLF7 = rowmax(SearchtoOOLF25 SearchtoOOLF26 SearchtoOOLF27 SearchtoOOLF28 SearchtoOOLF29 SearchtoOOLF30 SearchtoOOLF31 SearchtoOOLF32 SearchtoOOLF33 SearchtoOOLF34 SearchtoOOLF35 SearchtoOOLF36 SearchtoOOLF37 SearchtoOOLF38 SearchtoOOLF39 SearchtoOOLF40 SearchtoOOLF41 SearchtoOOLF42 SearchtoOOLF43 SearchtoOOLF44 SearchtoOOLF45 SearchtoOOLF46 SearchtoOOLF47 SearchtoOOLF48)
	
foreach x of numlist 50/72 { // 2009
	local j = `x' - 1
	replace SearchtoEmploy`x' = 1 if Searching`j' == 1 & Employed`x' == 1 & Employed`j' != 1
	replace SearchtoOOLF`x' = 1 if Searching`j' == 1 & Discouraged`x' == 1 & Employed`j' != 1	
}

	egen TransitionEmploy9 = rowmax(SearchtoEmploy49 SearchtoEmploy50 SearchtoEmploy51 SearchtoEmploy52 SearchtoEmploy53 SearchtoEmploy54 SearchtoEmploy55 SearchtoEmploy56 SearchtoEmploy57 SearchtoEmploy58 SearchtoEmploy59 SearchtoEmploy60 SearchtoEmploy61 SearchtoEmploy62 SearchtoEmploy63 SearchtoEmploy64 SearchtoEmploy65 SearchtoEmploy66 SearchtoEmploy67 SearchtoEmploy68 SearchtoEmploy69 SearchtoEmploy70 SearchtoEmploy71 SearchtoEmploy72)
	egen TransitionOOLF9 = rowmax(SearchtoOOLF49 SearchtoOOLF50 SearchtoOOLF51 SearchtoOOLF52 SearchtoOOLF53 SearchtoOOLF54 SearchtoOOLF55 SearchtoOOLF56 SearchtoOOLF57 SearchtoOOLF58 SearchtoOOLF59 SearchtoOOLF60 SearchtoOOLF61 SearchtoOOLF62 SearchtoOOLF63 SearchtoOOLF64 SearchtoOOLF65 SearchtoOOLF66 SearchtoOOLF67 SearchtoOOLF68 SearchtoOOLF69 SearchtoOOLF70 SearchtoOOLF71 SearchtoOOLF72)
	
foreach x of numlist 74/96 { // 2011
	local j = `x' - 1
	replace SearchtoEmploy`x' = 1 if Searching`j' == 1 & Employed`x' == 1 & Employed`j' != 1
	replace SearchtoOOLF`x' = 1 if Searching`j' == 1 & Discouraged`x' == 1 & Employed`j' != 1	
}

	egen TransitionEmploy11 = rowmax(SearchtoEmploy73 SearchtoEmploy74 SearchtoEmploy75 SearchtoEmploy76 SearchtoEmploy77 SearchtoEmploy78 SearchtoEmploy79 SearchtoEmploy80 SearchtoEmploy81 SearchtoEmploy82 SearchtoEmploy83 SearchtoEmploy84 SearchtoEmploy85 SearchtoEmploy86 SearchtoEmploy87 SearchtoEmploy88 SearchtoEmploy89 SearchtoEmploy90 SearchtoEmploy91 SearchtoEmploy92 SearchtoEmploy93 SearchtoEmploy94 SearchtoEmploy95 SearchtoEmploy96)
	egen TransitionOOLF11 = rowmax(SearchtoOOLF73 SearchtoOOLF74 SearchtoOOLF75 SearchtoOOLF76 SearchtoOOLF77 SearchtoOOLF78 SearchtoOOLF79 SearchtoOOLF80 SearchtoOOLF81 SearchtoOOLF82 SearchtoOOLF83 SearchtoOOLF84 SearchtoOOLF85 SearchtoOOLF86 SearchtoOOLF87 SearchtoOOLF88 SearchtoOOLF89 SearchtoOOLF90 SearchtoOOLF91 SearchtoOOLF92 SearchtoOOLF93 SearchtoOOLF94 SearchtoOOLF95 SearchtoOOLF96)
	
foreach x of numlist 98/120 { // 2013
	local j = `x' - 1
	replace SearchtoEmploy`x' = 1 if Searching`j' == 1 & Employed`x' == 1 & Employed`j' != 1
	replace SearchtoOOLF`x' = 1 if Searching`j' == 1 & Discouraged`x' == 1 & Employed`j' != 1	
}

	egen TransitionEmploy13 = rowmax(SearchtoEmploy97 SearchtoEmploy98 SearchtoEmploy99 SearchtoEmploy100 SearchtoEmploy101 SearchtoEmploy102 SearchtoEmploy103 SearchtoEmploy104 SearchtoEmploy105 SearchtoEmploy106 SearchtoEmploy107 SearchtoEmploy108 SearchtoEmploy109 SearchtoEmploy110 SearchtoEmploy111 SearchtoEmploy112 SearchtoEmploy113 SearchtoEmploy114 SearchtoEmploy115 SearchtoEmploy116 SearchtoEmploy117 SearchtoEmploy118 SearchtoEmploy119 SearchtoEmploy120)
	egen TransitionOOLF13 = rowmax(SearchtoOOLF97 SearchtoOOLF98 SearchtoOOLF99 SearchtoOOLF100 SearchtoOOLF101 SearchtoOOLF102 SearchtoOOLF103 SearchtoOOLF104 SearchtoOOLF105 SearchtoOOLF106 SearchtoOOLF107 SearchtoOOLF108 SearchtoOOLF109 SearchtoOOLF110 SearchtoOOLF111 SearchtoOOLF112 SearchtoOOLF113 SearchtoOOLF114 SearchtoOOLF115 SearchtoOOLF116 SearchtoOOLF117 SearchtoOOLF118 SearchtoOOLF119 SearchtoOOLF120)
	
foreach x of numlist 122/144 { // 2015
	local j = `x' - 1
	replace SearchtoEmploy`x' = 1 if Searching`j' == 1 & Employed`x' == 1 & Employed`j' != 1
	replace SearchtoOOLF`x' = 1 if Searching`j' == 1 & Discouraged`x' == 1 & Employed`j' != 1	
}

	egen TransitionEmploy15 = rowmax(SearchtoEmploy121 SearchtoEmploy122 SearchtoEmploy123 SearchtoEmploy124 SearchtoEmploy125 SearchtoEmploy126 SearchtoEmploy127 SearchtoEmploy128 SearchtoEmploy129 SearchtoEmploy130 SearchtoEmploy131 SearchtoEmploy132 SearchtoEmploy133 SearchtoEmploy134 SearchtoEmploy135 SearchtoEmploy136 SearchtoEmploy137 SearchtoEmploy138 SearchtoEmploy139 SearchtoEmploy140 SearchtoEmploy141 SearchtoEmploy142 SearchtoEmploy143 SearchtoEmploy144)
	egen TransitionOOLF15 = rowmax(SearchtoOOLF121 SearchtoOOLF122 SearchtoOOLF123 SearchtoOOLF124 SearchtoOOLF125 SearchtoOOLF126 SearchtoOOLF127 SearchtoOOLF128 SearchtoOOLF129 SearchtoOOLF130 SearchtoOOLF131 SearchtoOOLF132 SearchtoOOLF133 SearchtoOOLF134 SearchtoOOLF135 SearchtoOOLF136 SearchtoOOLF137 SearchtoOOLF138 SearchtoOOLF139 SearchtoOOLF140 SearchtoOOLF141 SearchtoOOLF142 SearchtoOOLF143 SearchtoOOLF144)

foreach x in 5 7 9 11 13 15 {
	replace TransitionEmploy`x' = 0 if TransitionEmploy`x' != 1
		replace TransitionEmploy`x' = . if TAS`x' != 1
	replace TransitionOOLF`x' = 0 if TransitionOOLF`x' != 1
		replace TransitionOOLF`x' = . if TAS`x' != 1
}

	
drop Searching1 Discouraged1 Searching2 Discouraged2 Searching3 Discouraged3 ///
	Searching4 Discouraged4 Searching5 Discouraged5 Searching6 Discouraged6 Searching7 ///
	Discouraged7 Searching8 Discouraged8 Searching9 Discouraged9 Searching10 ///
	Discouraged10 Searching11 Discouraged11 Searching12 Discouraged12 Searching13 ///
	Discouraged13 Searching14 Discouraged14 Searching15 Discouraged15 Searching16 ///
	Discouraged16 Searching17 Discouraged17 Searching18 Discouraged18 Searching19 ///
	Discouraged19 Searching20 Discouraged20 Searching21 Discouraged21 Searching22 ///
	Discouraged22 Searching23 Discouraged23 Searching24 Discouraged24 Searching25 ///
	Discouraged25 Searching26 Discouraged26 Searching27 Discouraged27 Searching28 ///
	Discouraged28 Searching29 Discouraged29 Searching30 Discouraged30 Searching31 ///
	Discouraged31 Searching32 Discouraged32 Searching33 Discouraged33 Searching34 ///
	Discouraged34 Searching35 Discouraged35 Searching36 Discouraged36 Searching37 ///
	Discouraged37 Searching38 Discouraged38 Searching39 Discouraged39 Searching40 ///
	Discouraged40 Searching41 Discouraged41 Searching42 Discouraged42 Searching43 ///
	Discouraged43 Searching44 Discouraged44 Searching45 Discouraged45 Searching46 ///
	Discouraged46 Searching47 Discouraged47 Searching48 Discouraged48 Searching49 ///
	Discouraged49 Searching50 Discouraged50 Searching51 Discouraged51 Searching52 ///
	Discouraged52 Searching53 Discouraged53 Searching54 Discouraged54 Searching55 ///
	Discouraged55 Searching56 Discouraged56 Searching57 Discouraged57 Searching58 ///
	Discouraged58 Searching59 Discouraged59 Searching60 Discouraged60 Searching61 ///
	Discouraged61 Searching62 Discouraged62 Searching63 Discouraged63 Searching64 ///
	Discouraged64 Searching65 Discouraged65 Searching66 Discouraged66 Searching67 ///
	Discouraged67 Searching68 Discouraged68 Searching69 Discouraged69 Searching70 ///
	Discouraged70 Searching71 Discouraged71 Searching72 Discouraged72 Searching73 ///
	Discouraged73 Searching74 Discouraged74 Searching75 Discouraged75 Searching76 ///
	Discouraged76 Searching77 Discouraged77 Searching78 Discouraged78 Searching79 ///
	Discouraged79 Searching80 Discouraged80 Searching81 Discouraged81 Searching82 ///
	Discouraged82 Searching83 Discouraged83 Searching84 Discouraged84 Searching85 ///
	Discouraged85 Searching86 Discouraged86 Searching87 Discouraged87 Searching88 ///
	Discouraged88 Searching89 Discouraged89 Searching90 Discouraged90 Searching91 ///
	Discouraged91 Searching92 Discouraged92 Searching93 Discouraged93 Searching94 ///
	Discouraged94 Searching95 Discouraged95 Searching96 Discouraged96 Searching97 ///
	Discouraged97 Searching98 Discouraged98 Searching99 Discouraged99 Searching100 ///
	Discouraged100 Searching101 Discouraged101 Searching102 Discouraged102 ///
	Searching103 Discouraged103 Searching104 Discouraged104 Searching105 ///
	Discouraged105 Searching106 Discouraged106 Searching107 Discouraged107 ///
	Searching108 Discouraged108 Searching109 Discouraged109 Searching110 ///
	Discouraged110 Searching111 Discouraged111 Searching112 Discouraged112 ///
	Searching113 Discouraged113 Searching114 Discouraged114 Searching115 ///
	Discouraged115 Searching116 Discouraged116 Searching117 Discouraged117 ///
	Searching118 Discouraged118 Searching119 Discouraged119 Searching120 ///
	Discouraged120 Searching121 Discouraged121 Searching122 Discouraged122 ///
	Searching123 Discouraged123 Searching124 Discouraged124 Searching125 ///
	Discouraged125 Searching126 Discouraged126 Searching127 Discouraged127 ///
	Searching128 Discouraged128 Searching129 Discouraged129 Searching130 ///
	Discouraged130 Searching131 Discouraged131 Searching132 Discouraged132 ///
	Searching133 Discouraged133 Searching134 Discouraged134 Searching135 ///
	Discouraged135 Searching136 Discouraged136 Searching137 Discouraged137 ///
	Searching138 Discouraged138 Searching139 Discouraged139 Searching140 ///
	Discouraged140 Searching141 Discouraged141 Searching142 Discouraged142 ///
	Searching143 Discouraged143 Searching144 Discouraged144 Employed1 Employed2 ///
	Employed3 Employed4 Employed5 Employed6 Employed7 Employed8 Employed9 ///
	Employed10 Employed11 Employed12 Employed13 Employed14 Employed15 Employed16 ///
	Employed17 Employed18 Employed19 Employed20 Employed21 Employed22 Employed23 ///
	Employed24 Employed25 Employed26 Employed27 Employed28 Employed29 Employed30 ///
	Employed31 Employed32 Employed33 Employed34 Employed35 Employed36 Employed37 ///
	Employed38 Employed39 Employed40 Employed41 Employed42 Employed43 Employed44 ///
	Employed45 Employed46 Employed47 Employed48 Employed49 Employed50 Employed51 ///
	Employed52 Employed53 Employed54 Employed55 Employed56 Employed57 Employed58 ///
	Employed59 Employed60 Employed61 Employed62 Employed63 Employed64 Employed65 ///
	Employed66 Employed67 Employed68 Employed69 Employed70 Employed71 Employed72 ///
	Employed73 Employed74 Employed75 Employed76 Employed77 Employed78 Employed79 ///
	Employed80 Employed81 Employed82 Employed83 Employed84 Employed85 Employed86 ///
	Employed87 Employed88 Employed89 Employed90 Employed91 Employed92 Employed93 ///
	Employed94 Employed95 Employed96 Employed97 Employed98 Employed99 Employed100 ///
	Employed101 Employed102 Employed103 Employed104 Employed105 Employed106 ///
	Employed107 Employed108 Employed109 Employed110 Employed111 Employed112 ///
	Employed113 Employed114 Employed115 Employed116 Employed117 Employed118 ///
	Employed119 Employed120 Employed121 Employed122 Employed123 Employed124 ///
	Employed125 Employed126 Employed127 Employed128 Employed129 Employed130 ///
	Employed131 Employed132 Employed133 Employed134 Employed135 Employed136 ///
	Employed137 Employed138 Employed139 Employed140 Employed141 Employed142 ///
	Employed143 Employed144 ethree_3 esix_3 etwelve_3 sthree_3 ssix_3 stwelve_3 ///
	dthree_3 dsix_3 dtwelve_3 ethree_4 esix_4 etwelve_4 sthree_4 ssix_4 stwelve_4 ///
	dthree_4 dsix_4 dtwelve_4 ethree_5 esix_5 etwelve_5 sthree_5 ssix_5 stwelve_5 ///
	dthree_5 dsix_5 dtwelve_5 ethree_6 esix_6 etwelve_6 sthree_6 ssix_6 stwelve_6 ///
	dthree_6 dsix_6 dtwelve_6 ethree_7 esix_7 etwelve_7 sthree_7 ssix_7 stwelve_7 ///
	dthree_7 dsix_7 dtwelve_7 ethree_8 esix_8 etwelve_8 sthree_8 ssix_8 stwelve_8 ///
	dthree_8 dsix_8 dtwelve_8 ethree_9 esix_9 etwelve_9 sthree_9 ssix_9 stwelve_9 ///
	dthree_9 dsix_9 dtwelve_9 ethree_10 esix_10 etwelve_10 sthree_10 ssix_10 ///
	stwelve_10 dthree_10 dsix_10 dtwelve_10 ethree_11 esix_11 etwelve_11 sthree_11 ///
	ssix_11 stwelve_11 dthree_11 dsix_11 dtwelve_11 ethree_12 esix_12 etwelve_12 ///
	sthree_12 ssix_12 stwelve_12 dthree_12 dsix_12 dtwelve_12 ethree_13 esix_13 ///
	etwelve_13 sthree_13 ssix_13 stwelve_13 dthree_13 dsix_13 dtwelve_13 ethree_14 ///
	esix_14 etwelve_14 sthree_14 ssix_14 stwelve_14 dthree_14 dsix_14 dtwelve_14 ///
	ethree_15 esix_15 etwelve_15 sthree_15 ssix_15 stwelve_15 dthree_15 dsix_15 ///
	dtwelve_15 ethree_16 esix_16 etwelve_16 sthree_16 ssix_16 stwelve_16 dthree_16 ///
	dsix_16 dtwelve_16 ethree_17 esix_17 etwelve_17 sthree_17 ssix_17 stwelve_17 ///
	dthree_17 dsix_17 dtwelve_17 ethree_18 esix_18 etwelve_18 sthree_18 ssix_18 ///
	stwelve_18 dthree_18 dsix_18 dtwelve_18 ethree_19 esix_19 etwelve_19 sthree_19 ///
	ssix_19 stwelve_19 dthree_19 dsix_19 dtwelve_19 ethree_20 esix_20 etwelve_20 ///
	sthree_20 ssix_20 stwelve_20 dthree_20 dsix_20 dtwelve_20 ethree_21 esix_21 ///
	etwelve_21 sthree_21 ssix_21 stwelve_21 dthree_21 dsix_21 dtwelve_21 ethree_22 ///
	esix_22 etwelve_22 sthree_22 ssix_22 stwelve_22 dthree_22 dsix_22 dtwelve_22 ///
	ethree_23 esix_23 etwelve_23 sthree_23 ssix_23 stwelve_23 dthree_23 dsix_23 ///
	dtwelve_23 ethree_24 esix_24 etwelve_24 sthree_24 ssix_24 stwelve_24 dthree_24 ///
	dsix_24 dtwelve_24 ethree_27 esix_27 etwelve_27 sthree_27 ssix_27 stwelve_27 ///
	dthree_27 dsix_27 dtwelve_27 ethree_28 esix_28 etwelve_28 sthree_28 ssix_28 ///
	stwelve_28 dthree_28 dsix_28 dtwelve_28 ethree_29 esix_29 etwelve_29 sthree_29 ///
	ssix_29 stwelve_29 dthree_29 dsix_29 dtwelve_29 ethree_30 esix_30 etwelve_30 ///
	sthree_30 ssix_30 stwelve_30 dthree_30 dsix_30 dtwelve_30 ethree_31 esix_31 ///
	etwelve_31 sthree_31 ssix_31 stwelve_31 dthree_31 dsix_31 dtwelve_31 ethree_32 ///
	esix_32 etwelve_32 sthree_32 ssix_32 stwelve_32 dthree_32 dsix_32 dtwelve_32 ///
	ethree_33 esix_33 etwelve_33 sthree_33 ssix_33 stwelve_33 dthree_33 dsix_33 ///
	dtwelve_33 ethree_34 esix_34 etwelve_34 sthree_34 ssix_34 stwelve_34 dthree_34 ///
	dsix_34 dtwelve_34 ethree_35 esix_35 etwelve_35 sthree_35 ssix_35 stwelve_35 ///
	dthree_35 dsix_35 dtwelve_35 ethree_36 esix_36 etwelve_36 sthree_36 ssix_36 ///
	stwelve_36 dthree_36 dsix_36 dtwelve_36 ethree_37 esix_37 etwelve_37 sthree_37 ///
	ssix_37 stwelve_37 dthree_37 dsix_37 dtwelve_37 ethree_38 esix_38 etwelve_38 ///
	sthree_38 ssix_38 stwelve_38 dthree_38 dsix_38 dtwelve_38 ethree_39 esix_39 ///
	etwelve_39 sthree_39 ssix_39 stwelve_39 dthree_39 dsix_39 dtwelve_39 ethree_40 ///
	esix_40 etwelve_40 sthree_40 ssix_40 stwelve_40 dthree_40 dsix_40 dtwelve_40 ///
	ethree_41 esix_41 etwelve_41 sthree_41 ssix_41 stwelve_41 dthree_41 dsix_41 ///
	dtwelve_41 ethree_42 esix_42 etwelve_42 sthree_42 ssix_42 stwelve_42 dthree_42 ///
	dsix_42 dtwelve_42 ethree_43 esix_43 etwelve_43 sthree_43 ssix_43 stwelve_43 ///
	dthree_43 dsix_43 dtwelve_43 ethree_44 esix_44 etwelve_44 sthree_44 ssix_44 ///
	stwelve_44 dthree_44 dsix_44 dtwelve_44 ethree_45 esix_45 etwelve_45 sthree_45 ///
	ssix_45 stwelve_45 dthree_45 dsix_45 dtwelve_45 ethree_46 esix_46 etwelve_46 ///
	sthree_46 ssix_46 stwelve_46 dthree_46 dsix_46 dtwelve_46 ethree_47 esix_47 ///
	etwelve_47 sthree_47 ssix_47 stwelve_47 dthree_47 dsix_47 dtwelve_47 ethree_48 ///
	esix_48 etwelve_48 sthree_48 ssix_48 stwelve_48 dthree_48 dsix_48 dtwelve_48 ///
	ethree_51 esix_51 etwelve_51 sthree_51 ssix_51 stwelve_51 dthree_51 dsix_51 ///
	dtwelve_51 ethree_52 esix_52 etwelve_52 sthree_52 ssix_52 stwelve_52 dthree_52 ///
	dsix_52 dtwelve_52 ethree_53 esix_53 etwelve_53 sthree_53 ssix_53 stwelve_53 ///
	dthree_53 dsix_53 dtwelve_53 ethree_54 esix_54 etwelve_54 sthree_54 ssix_54 ///
	stwelve_54 dthree_54 dsix_54 dtwelve_54 ethree_55 esix_55 etwelve_55 sthree_55 ///
	ssix_55 stwelve_55 dthree_55 dsix_55 dtwelve_55 ethree_56 esix_56 etwelve_56 ///
	sthree_56 ssix_56 stwelve_56 dthree_56 dsix_56 dtwelve_56 ethree_57 esix_57 ///
	etwelve_57 sthree_57 ssix_57 stwelve_57 dthree_57 dsix_57 dtwelve_57 ethree_58 ///
	esix_58 etwelve_58 sthree_58 ssix_58 stwelve_58 dthree_58 dsix_58 dtwelve_58 ///
	ethree_59 esix_59 etwelve_59 sthree_59 ssix_59 stwelve_59 dthree_59 dsix_59 ///
	dtwelve_59 ethree_60 esix_60 etwelve_60 sthree_60 ssix_60 stwelve_60 dthree_60 ///
	dsix_60 dtwelve_60 ethree_61 esix_61 etwelve_61 sthree_61 ssix_61 stwelve_61 ///
	dthree_61 dsix_61 dtwelve_61 ethree_62 esix_62 etwelve_62 sthree_62 ssix_62 ///
	stwelve_62 dthree_62 dsix_62 dtwelve_62 ethree_63 esix_63 etwelve_63 sthree_63 ///
	ssix_63 stwelve_63 dthree_63 dsix_63 dtwelve_63 ethree_64 esix_64 etwelve_64 ///
	sthree_64 ssix_64 stwelve_64 dthree_64 dsix_64 dtwelve_64 ethree_65 esix_65 ///
	etwelve_65 sthree_65 ssix_65 stwelve_65 dthree_65 dsix_65 dtwelve_65 ethree_66 ///
	esix_66 etwelve_66 sthree_66 ssix_66 stwelve_66 dthree_66 dsix_66 dtwelve_66 ///
	ethree_67 esix_67 etwelve_67 sthree_67 ssix_67 stwelve_67 dthree_67 dsix_67 ///
	dtwelve_67 ethree_68 esix_68 etwelve_68 sthree_68 ssix_68 stwelve_68 dthree_68 ///
	dsix_68 dtwelve_68 ethree_69 esix_69 etwelve_69 sthree_69 ssix_69 stwelve_69 ///
	dthree_69 dsix_69 dtwelve_69 ethree_70 esix_70 etwelve_70 sthree_70 ssix_70 ///
	stwelve_70 dthree_70 dsix_70 dtwelve_70 ethree_71 esix_71 etwelve_71 sthree_71 ///
	ssix_71 stwelve_71 dthree_71 dsix_71 dtwelve_71 ethree_72 esix_72 etwelve_72 ///
	sthree_72 ssix_72 stwelve_72 dthree_72 dsix_72 dtwelve_72 ethree_75 esix_75 ///
	etwelve_75 sthree_75 ssix_75 stwelve_75 dthree_75 dsix_75 dtwelve_75 ethree_76 ///
	esix_76 etwelve_76 sthree_76 ssix_76 stwelve_76 dthree_76 dsix_76 dtwelve_76 ///
	ethree_77 esix_77 etwelve_77 sthree_77 ssix_77 stwelve_77 dthree_77 dsix_77 ///
	dtwelve_77 ethree_78 esix_78 etwelve_78 sthree_78 ssix_78 stwelve_78 dthree_78 ///
	dsix_78 dtwelve_78 ethree_79 esix_79 etwelve_79 sthree_79 ssix_79 stwelve_79 ///
	dthree_79 dsix_79 dtwelve_79 ethree_80 esix_80 etwelve_80 sthree_80 ssix_80 ///
	stwelve_80 dthree_80 dsix_80 dtwelve_80 ethree_81 esix_81 etwelve_81 sthree_81 ///
	ssix_81 stwelve_81 dthree_81 dsix_81 dtwelve_81 ethree_82 esix_82 etwelve_82 ///
	sthree_82 ssix_82 stwelve_82 dthree_82 dsix_82 dtwelve_82 ethree_83 esix_83 ///
	etwelve_83 sthree_83 ssix_83 stwelve_83 dthree_83 dsix_83 dtwelve_83 ethree_84 ///
	esix_84 etwelve_84 sthree_84 ssix_84 stwelve_84 dthree_84 dsix_84 dtwelve_84 ///
	ethree_85 esix_85 etwelve_85 sthree_85 ssix_85 stwelve_85 dthree_85 dsix_85 ///
	dtwelve_85 ethree_86 esix_86 etwelve_86 sthree_86 ssix_86 stwelve_86 dthree_86 ///
	dsix_86 dtwelve_86 ethree_87 esix_87 etwelve_87 sthree_87 ssix_87 stwelve_87 ///
	dthree_87 dsix_87 dtwelve_87 ethree_88 esix_88 etwelve_88 sthree_88 ssix_88 ///
	stwelve_88 dthree_88 dsix_88 dtwelve_88 ethree_89 esix_89 etwelve_89 sthree_89 ///
	ssix_89 stwelve_89 dthree_89 dsix_89 dtwelve_89 ethree_90 esix_90 etwelve_90 ///
	sthree_90 ssix_90 stwelve_90 dthree_90 dsix_90 dtwelve_90 ethree_91 esix_91 ///
	etwelve_91 sthree_91 ssix_91 stwelve_91 dthree_91 dsix_91 dtwelve_91 ethree_92 ///
	esix_92 etwelve_92 sthree_92 ssix_92 stwelve_92 dthree_92 dsix_92 dtwelve_92 ///
	ethree_93 esix_93 etwelve_93 sthree_93 ssix_93 stwelve_93 dthree_93 dsix_93 ///
	dtwelve_93 ethree_94 esix_94 etwelve_94 sthree_94 ssix_94 stwelve_94 dthree_94 ///
	dsix_94 dtwelve_94 ethree_95 esix_95 etwelve_95 sthree_95 ssix_95 stwelve_95 ///
	dthree_95 dsix_95 dtwelve_95 ethree_96 esix_96 etwelve_96 sthree_96 ssix_96 ///
	stwelve_96 dthree_96 dsix_96 dtwelve_96 ethree_99 esix_99 etwelve_99 sthree_99 ///
	ssix_99 stwelve_99 dthree_99 dsix_99 dtwelve_99 ethree_100 esix_100 etwelve_100 ///
	sthree_100 ssix_100 stwelve_100 dthree_100 dsix_100 dtwelve_100 ethree_101 ///
	esix_101 etwelve_101 sthree_101 ssix_101 stwelve_101 dthree_101 dsix_101 ///
	dtwelve_101 ethree_102 esix_102 etwelve_102 sthree_102 ssix_102 stwelve_102 ///
	dthree_102 dsix_102 dtwelve_102 ethree_103 esix_103 etwelve_103 sthree_103 ///
	ssix_103 stwelve_103 dthree_103 dsix_103 dtwelve_103 ethree_104 esix_104 ///
	etwelve_104 sthree_104 ssix_104 stwelve_104 dthree_104 dsix_104 dtwelve_104 ///
	ethree_105 esix_105 etwelve_105 sthree_105 ssix_105 stwelve_105 dthree_105 ///
	dsix_105 dtwelve_105 ethree_106 esix_106 etwelve_106 sthree_106 ssix_106 ///
	stwelve_106 dthree_106 dsix_106 dtwelve_106 ethree_107 esix_107 etwelve_107 ///
	sthree_107 ssix_107 stwelve_107 dthree_107 dsix_107 dtwelve_107 ethree_108 ///
	esix_108 etwelve_108 sthree_108 ssix_108 stwelve_108 dthree_108 dsix_108 ///
	dtwelve_108 ethree_109 esix_109 etwelve_109 sthree_109 ssix_109 stwelve_109 ///
	dthree_109 dsix_109 dtwelve_109 ethree_110 esix_110 etwelve_110 sthree_110 ///
	ssix_110 stwelve_110 dthree_110 dsix_110 dtwelve_110 ethree_111 esix_111 ///
	etwelve_111 sthree_111 ssix_111 stwelve_111 dthree_111 dsix_111 dtwelve_111 ///
	ethree_112 esix_112 etwelve_112 sthree_112 ssix_112 stwelve_112 dthree_112 ///
	dsix_112 dtwelve_112 ethree_113 esix_113 etwelve_113 sthree_113 ssix_113 ///
	stwelve_113 dthree_113 dsix_113 dtwelve_113 ethree_114 esix_114 etwelve_114 ///
	sthree_114 ssix_114 stwelve_114 dthree_114 dsix_114 dtwelve_114 ethree_115 ///
	esix_115 etwelve_115 sthree_115 ssix_115 stwelve_115 dthree_115 dsix_115 ///
	dtwelve_115 ethree_116 esix_116 etwelve_116 sthree_116 ssix_116 stwelve_116 ///
	dthree_116 dsix_116 dtwelve_116 ethree_117 esix_117 etwelve_117 sthree_117 ///
	ssix_117 stwelve_117 dthree_117 dsix_117 dtwelve_117 ethree_118 esix_118 ///
	etwelve_118 sthree_118 ssix_118 stwelve_118 dthree_118 dsix_118 dtwelve_118 ///
	ethree_119 esix_119 etwelve_119 sthree_119 ssix_119 stwelve_119 dthree_119 ///
	dsix_119 dtwelve_119 ethree_120 esix_120 etwelve_120 sthree_120 ssix_120 ///
	stwelve_120 dthree_120 dsix_120 dtwelve_120 ethree_123 esix_123 etwelve_123 ///
	sthree_123 ssix_123 stwelve_123 dthree_123 dsix_123 dtwelve_123 ethree_124 ///
	esix_124 etwelve_124 sthree_124 ssix_124 stwelve_124 dthree_124 dsix_124 ///
	dtwelve_124 ethree_125 esix_125 etwelve_125 sthree_125 ssix_125 stwelve_125 ///
	dthree_125 dsix_125 dtwelve_125 ethree_126 esix_126 etwelve_126 sthree_126 ///
	ssix_126 stwelve_126 dthree_126 dsix_126 dtwelve_126 ethree_127 esix_127 ///
	etwelve_127 sthree_127 ssix_127 stwelve_127 dthree_127 dsix_127 dtwelve_127 ///
	ethree_128 esix_128 etwelve_128 sthree_128 ssix_128 stwelve_128 dthree_128 ///
	dsix_128 dtwelve_128 ethree_129 esix_129 etwelve_129 sthree_129 ssix_129 ///
	stwelve_129 dthree_129 dsix_129 dtwelve_129 ethree_130 esix_130 etwelve_130 ///
	sthree_130 ssix_130 stwelve_130 dthree_130 dsix_130 dtwelve_130 ethree_131 ///
	esix_131 etwelve_131 sthree_131 ssix_131 stwelve_131 dthree_131 dsix_131 ///
	dtwelve_131 ethree_132 esix_132 etwelve_132 sthree_132 ssix_132 stwelve_132 ///
	dthree_132 dsix_132 dtwelve_132 ethree_133 esix_133 etwelve_133 sthree_133 ///
	ssix_133 stwelve_133 dthree_133 dsix_133 dtwelve_133 ethree_134 esix_134 ///
	etwelve_134 sthree_134 ssix_134 stwelve_134 dthree_134 dsix_134 dtwelve_134 ///
	ethree_135 esix_135 etwelve_135 sthree_135 ssix_135 stwelve_135 dthree_135 ///
	dsix_135 dtwelve_135 ethree_136 esix_136 etwelve_136 sthree_136 ssix_136 ///
	stwelve_136 dthree_136 dsix_136 dtwelve_136 ethree_137 esix_137 etwelve_137 ///
	sthree_137 ssix_137 stwelve_137 dthree_137 dsix_137 dtwelve_137 ethree_138 ///
	esix_138 etwelve_138 sthree_138 ssix_138 stwelve_138 dthree_138 dsix_138 ///
	dtwelve_138 ethree_139 esix_139 etwelve_139 sthree_139 ssix_139 stwelve_139 ///
	dthree_139 dsix_139 dtwelve_139 ethree_140 esix_140 etwelve_140 sthree_140 ///
	ssix_140 stwelve_140 dthree_140 dsix_140 dtwelve_140 ethree_141 esix_141 ///
	etwelve_141 sthree_141 ssix_141 stwelve_141 dthree_141 dsix_141 dtwelve_141 ///
	ethree_142 esix_142 etwelve_142 sthree_142 ssix_142 stwelve_142 dthree_142 ///
	dsix_142 dtwelve_142 ethree_143 esix_143 etwelve_143 sthree_143 ssix_143 ///
	stwelve_143 dthree_143 dsix_143 dtwelve_143 ethree_144 esix_144 etwelve_144 ///
	sthree_144 ssix_144 stwelve_144 dthree_144 dsix_144 dtwelve_144 SearchtoEmploy1 ///
	SearchtoEmploy2 SearchtoEmploy3 SearchtoEmploy4 SearchtoEmploy5 SearchtoEmploy6 ///
	SearchtoEmploy7 SearchtoEmploy8 SearchtoEmploy9 SearchtoEmploy10 SearchtoEmploy11 ///
	SearchtoEmploy12 SearchtoEmploy13 SearchtoEmploy14 SearchtoEmploy15 SearchtoEmploy16 ///
	SearchtoEmploy17 SearchtoEmploy18 SearchtoEmploy19 SearchtoEmploy20 SearchtoEmploy21 ///
	SearchtoEmploy22 SearchtoEmploy23 SearchtoEmploy24 SearchtoEmploy25 SearchtoEmploy26 ///
	SearchtoEmploy27 SearchtoEmploy28 SearchtoEmploy29 SearchtoEmploy30 SearchtoEmploy31 ///
	SearchtoEmploy32 SearchtoEmploy33 SearchtoEmploy34 SearchtoEmploy35 SearchtoEmploy36 ///
	SearchtoEmploy37 SearchtoEmploy38 SearchtoEmploy39 SearchtoEmploy40 SearchtoEmploy41 ///
	SearchtoEmploy42 SearchtoEmploy43 SearchtoEmploy44 SearchtoEmploy45 SearchtoEmploy46 ///
	SearchtoEmploy47 SearchtoEmploy48 SearchtoEmploy49 SearchtoEmploy50 SearchtoEmploy51 ///
	SearchtoEmploy52 SearchtoEmploy53 SearchtoEmploy54 SearchtoEmploy55 SearchtoEmploy56 ///
	SearchtoEmploy57 SearchtoEmploy58 SearchtoEmploy59 SearchtoEmploy60 SearchtoEmploy61 ///
	SearchtoEmploy62 SearchtoEmploy63 SearchtoEmploy64 SearchtoEmploy65 SearchtoEmploy66 ///
	SearchtoEmploy67 SearchtoEmploy68 SearchtoEmploy69 SearchtoEmploy70 SearchtoEmploy71 ///
	SearchtoEmploy72 SearchtoEmploy73 SearchtoEmploy74 SearchtoEmploy75 SearchtoEmploy76 ///
	SearchtoEmploy77 SearchtoEmploy78 SearchtoEmploy79 SearchtoEmploy80 SearchtoEmploy81 ///
	SearchtoEmploy82 SearchtoEmploy83 SearchtoEmploy84 SearchtoEmploy85 SearchtoEmploy86 ///
	SearchtoEmploy87 SearchtoEmploy88 SearchtoEmploy89 SearchtoEmploy90 SearchtoEmploy91 ///
	SearchtoEmploy92 SearchtoEmploy93 SearchtoEmploy94 SearchtoEmploy95 SearchtoEmploy96 ///
	SearchtoEmploy97 SearchtoEmploy98 SearchtoEmploy99 SearchtoEmploy100 SearchtoEmploy101 ///
	SearchtoEmploy102 SearchtoEmploy103 SearchtoEmploy104 SearchtoEmploy105 SearchtoEmploy106 ///
	SearchtoEmploy107 SearchtoEmploy108 SearchtoEmploy109 SearchtoEmploy110 SearchtoEmploy111 ///
	SearchtoEmploy112 SearchtoEmploy113 SearchtoEmploy114 SearchtoEmploy115 SearchtoEmploy116 ///
	SearchtoEmploy117 SearchtoEmploy118 SearchtoEmploy119 SearchtoEmploy120 SearchtoEmploy121 ///
	SearchtoEmploy122 SearchtoEmploy123 SearchtoEmploy124 SearchtoEmploy125 SearchtoEmploy126 ///
	SearchtoEmploy127 SearchtoEmploy128 SearchtoEmploy129 SearchtoEmploy130 SearchtoEmploy131 ///
	SearchtoEmploy132 SearchtoEmploy133 SearchtoEmploy134 SearchtoEmploy135 SearchtoEmploy136 ///
	SearchtoEmploy137 SearchtoEmploy138 SearchtoEmploy139 SearchtoEmploy140 SearchtoEmploy141 ///
	SearchtoEmploy142 SearchtoEmploy143 SearchtoEmploy144 SearchtoOOLF1 SearchtoOOLF2 ///
	SearchtoOOLF3 SearchtoOOLF4 SearchtoOOLF5 SearchtoOOLF6 SearchtoOOLF7 SearchtoOOLF8 ///
	SearchtoOOLF9 SearchtoOOLF10 SearchtoOOLF11 SearchtoOOLF12 SearchtoOOLF13 ///
	SearchtoOOLF14 SearchtoOOLF15 SearchtoOOLF16 SearchtoOOLF17 SearchtoOOLF18 ///
	SearchtoOOLF19 SearchtoOOLF20 SearchtoOOLF21 SearchtoOOLF22 SearchtoOOLF23 ///
	SearchtoOOLF24 SearchtoOOLF25 SearchtoOOLF26 SearchtoOOLF27 SearchtoOOLF28 ///
	SearchtoOOLF29 SearchtoOOLF30 SearchtoOOLF31 SearchtoOOLF32 SearchtoOOLF33 ///
	SearchtoOOLF34 SearchtoOOLF35 SearchtoOOLF36 SearchtoOOLF37 SearchtoOOLF38 ///
	SearchtoOOLF39 SearchtoOOLF40 SearchtoOOLF41 SearchtoOOLF42 SearchtoOOLF43 ///
	SearchtoOOLF44 SearchtoOOLF45 SearchtoOOLF46 SearchtoOOLF47 SearchtoOOLF48 ///
	SearchtoOOLF49 SearchtoOOLF50 SearchtoOOLF51 SearchtoOOLF52 SearchtoOOLF53 ///
	SearchtoOOLF54 SearchtoOOLF55 SearchtoOOLF56 SearchtoOOLF57 SearchtoOOLF58 ///
	SearchtoOOLF59 SearchtoOOLF60 SearchtoOOLF61 SearchtoOOLF62 SearchtoOOLF63 ///
	SearchtoOOLF64 SearchtoOOLF65 SearchtoOOLF66 SearchtoOOLF67 SearchtoOOLF68 ///
	SearchtoOOLF69 SearchtoOOLF70 SearchtoOOLF71 SearchtoOOLF72 SearchtoOOLF73 ///
	SearchtoOOLF74 SearchtoOOLF75 SearchtoOOLF76 SearchtoOOLF77 SearchtoOOLF78 ///
	SearchtoOOLF79 SearchtoOOLF80 SearchtoOOLF81 SearchtoOOLF82 SearchtoOOLF83 ///
	SearchtoOOLF84 SearchtoOOLF85 SearchtoOOLF86 SearchtoOOLF87 SearchtoOOLF88 ///
	SearchtoOOLF89 SearchtoOOLF90 SearchtoOOLF91 SearchtoOOLF92 SearchtoOOLF93 ///
	SearchtoOOLF94 SearchtoOOLF95 SearchtoOOLF96 SearchtoOOLF97 SearchtoOOLF98 ///
	SearchtoOOLF99 SearchtoOOLF100 SearchtoOOLF101 SearchtoOOLF102 SearchtoOOLF103 ///
	SearchtoOOLF104 SearchtoOOLF105 SearchtoOOLF106 SearchtoOOLF107 SearchtoOOLF108 ///
	SearchtoOOLF109 SearchtoOOLF110 SearchtoOOLF111 SearchtoOOLF112 SearchtoOOLF113 ///
	SearchtoOOLF114 SearchtoOOLF115 SearchtoOOLF116 SearchtoOOLF117 SearchtoOOLF118 ///
	SearchtoOOLF119 SearchtoOOLF120 SearchtoOOLF121 SearchtoOOLF122 SearchtoOOLF123 ///
	SearchtoOOLF124 SearchtoOOLF125 SearchtoOOLF126 SearchtoOOLF127 SearchtoOOLF128 ///
	SearchtoOOLF129 SearchtoOOLF130 SearchtoOOLF131 SearchtoOOLF132 SearchtoOOLF133 ///
	SearchtoOOLF134 SearchtoOOLF135 SearchtoOOLF136 SearchtoOOLF137 SearchtoOOLF138 ///
	SearchtoOOLF139 SearchtoOOLF140 SearchtoOOLF141 SearchtoOOLF142 SearchtoOOLF143 ///
	SearchtoOOLF144


*SAVING DATA
cd "E:\[Anonymized]\Job Search\LMParticipation_PublicFiles\DataPull_PSID\Cleaned"
save "FinalData_Cleaned.dta", replace

log close 
cls
*/






********************************************************************************
********************************************************************************
*******************************  DATA ANALYSIS  ********************************
********************************************************************************
********************************************************************************

log using "E:\[Anonymized]\Job Search\LMParticipation_PublicFiles\Log Output\SECTION 3 - Data Assessments", ///
	text replace

use "E:\[Anonymized]\Job Search\LMParticipation_PublicFiles\DataPull_PSID\Cleaned\FinalData_Cleaned.dta", clear

keep  TAS TAS5 TAS7 TAS9 TAS11 TAS13 TAS15 Sex Race WorryJob5 WorryJob7 WorryJob9 ///
	WorryJob11 WorryJob13 WorryJob15 ArrestEver5 ArrestEver7 ArrestEver9 ///
	ArrestEver11 ArrestEver13 ArrestEver15 ProbationEver5 ProbationEver7 ///
	ProbationEver9 ProbationEver11 ProbationEver13 ProbationEver15 JailEver5 ///
	JailEver7 JailEver9 JailEver11 JailEver13 JailEver15 OffLastArrest15 ///
	OffLastProbation5 OffLastJail5 OffLastArrest7 OffLastProbation7 OffLastJail7 ///
	OffLastArrest9 OffLastProbation9 OffLastJail9 OffLastArrest13 OffLastProbation11 ///
	OffLastJail11 OffLastArrest5 OffLastProbation13 OffLastJail13 OffLastArrest11 ///
	OffLastProbation15 OffLastJail15 AgeLastArrest5 AgeLastProbation5 AgeLastJail5 ///
	AgeLastArrest7 AgeLastProbation7 AgeLastJail7 AgeLastArrest9 AgeLastProbation9 ///
	AgeLastJail9 AgeLastArrest11 AgeLastProbation11 AgeLastJail11 AgeLastArrest13 ///
	AgeLastProbation13 AgeLastJail13 AgeLastArrest15 AgeLastProbation15 AgeLastJail15 ///
	GraduatedHS5 GraduatedHS7 GraduatedHS9 GraduatedHS11 GraduatedHS13 GraduatedHS15 ///
	EnrollNow5 EnrollNow7 EnrollNow9 EnrollNow11 EnrollNow13 EnrollNow15 ///
	RelationshipStatus5 RelationshipStatus7 RelationshipStatus9 RelationshipStatus11 ///
	RelationshipStatus13 RelationshipStatus15 KidsYN5 KidsYN7 KidsYN9 KidsYN11 ///
	KidsYN13 KidsYN15 FIN_Scale5 FIN_Scale7 FIN_Scale9 FIN_Scale11 FIN_Scale13 ///
	FIN_Scale15 Risky5 Risky7 Risky9 Risky11 Risky13 Risky15 UnemploymentComp5 ///
	UnemploymentComp7 UnemploymentComp9 UnemploymentComp11 UnemploymentComp13 ///
	UnemploymentComp15 AGE11 AGE13 AGE15 AGE5 AGE7 AGE9 AlcUse11 AlcUse13 AlcUse15 ///
	AlcUse5 AlcUse7 AlcUse9 Health11 Health13 Health15 Health5 Health7 Health9 ParticipantID ///
	Discgd_Total11 Discgd_Total13 Discgd_Total15 Discgd_Total5 Discgd_Total7 ///
	Discgd_Total9 Employed_Total11 Employed_Total13 Employed_Total15 Employed_Total5 ///
	Employed_Total7 Employed_Total9 Searching_Total11 Searching_Total13 Searching_Total15 ///
	Searching_Total5 Searching_Total7 Searching_Total9 s_OffLastArrest5 s_OffLastArrest7 ///
	s_OffLastArrest11 s_OffLastArrest13 s_OffLastArrest15 s_OffLastProbation5 ///
	s_OffLastProbation7 s_OffLastProbation9 s_OffLastProbation11 s_OffLastProbation13 ///
	s_OffLastProbation15 s_OffLastJail5 s_OffLastJail7 s_OffLastJail9 ///
	s_OffLastJail11 s_OffLastJail13 s_OffLastJail15 s_OffLastArrest9 Benefits11 ///
	Benefits13 Benefits15 Benefits7 Benefits9 EarningsLY9 EarningsLY13 EarningsLY11 ///
	EarningsLY5 EarningsLY7 EarningsLY15 EarningsBefore9 EarningsBefore13 ///
	EarningsBefore11 EarningsBefore7 EarningsBefore15 OCC5 OCC7 OCC9 OCC11 OCC13 ///
	OCC15 DIS_Scale5 DIS_Scale7 DIS_Scale9 DIS_Scale11 DIS_Scale13 DIS_Scale15 ///
	TransitionEmploy5 TransitionOOLF5 TransitionEmploy7 TransitionOOLF7 ///
	TransitionEmploy9 TransitionOOLF9 TransitionEmploy11 TransitionOOLF11 ///
	TransitionEmploy13 TransitionOOLF13 TransitionEmploy15 TransitionOOLF15 ///
	ForceOut11 ForceOut13 ForceOut15 ForceOut5 ForceOut7 ForceOut9 ///
	FUT_Layoff5 FUT_Layoff7 FUT_Layoff9 FUT_Layoff11 FUT_Layoff13 FUT_Layoff15 ///
	LikelyPayWell5 LikelyPayWell7 LikelyPayWell9 LikelyPayWell11 LikelyPayWell13 LikelyPayWell15

	
***
*ADDITIONAL VARIABLE CLEANING
***

*2008 indicator
foreach x in 5 7 9 11 13 15 {
	gen crash`x' = .
	replace crash`x' = 1 if `x' > 8
	replace crash`x' = 0 if `x' < 8
	}
	
*Marital status
label define mar 0"Unmarried, not cohabitating" 1"Married or Cohabitating"
	// too few values for widowed/divorced/separated for separate category
foreach x in 5 7 9 11 13 15 {
	recode RelationshipStatus`x' 1=0 2/3=1 4=0 
	label value RelationshipStatus`x' mar	
}

*Offense type
label define offcat 0"Violent/Serious" 1"Non-Violent/Non-Serious"
label define soffcat2 0"No offense" 1"Violent/Serious" 2"Non-Violent/Non-Serious"
foreach x in Arrest Jail Probation {
	foreach y in 5 7 9 11 13 15 {
		clonevar Srs`x'`y' = OffLast`x'`y' // among those with record
			recode Srs`x'`y' 1/2=0 3/7=1
			label value Srs`x'`y' offcat
		clonevar s_Srs`x'`y' = s_OffLast`x'`y' // all respondents
			recode s_Srs`x'`y' 2=1 3/7=2
			label value s_Srs`x'`y' soffcat2
	}
}

*Earnings
foreach x in EarningsLY EarningsBefore {
	foreach y in 7 9 11 13 15 {
		// earnings year before last unavailable for 2005
		clonevar `x'_z`y' = `x'`y'
		replace `x'_z`y' = 0 if `x'_z`y' == .n
			// .n = no earnings
	}
}
	
foreach x in 7 9 11 13 15 {
	egen WaveEarnings`x' = rowtotal(EarningsLY`x' EarningsBefore`x')
		// without zero values
	egen WaveEarnings_z`x' = rowtotal(EarningsLY_z`x' EarningsBefore_z`x') 
		// with zero values
}

foreach x in 7 9 11 13 15 {
	gen EarningsPerMo`x' = (WaveEarnings`x' / Employed_Total`x')
	gen EarningsPerMo_z`x' = (WaveEarnings_z`x' / Employed_Total`x')
}

*Occupation
foreach x in 5 7 9 11 13 15 {
	replace OCC`x' = OCC`x' * 10 // aligned with occupation codes
	replace OCC`x' = .n if OCC`x' == 0
	replace OCC`x' = .d if OCC`x' == 9990
}
	// occupation codes will be merged later
	
*Any time in state
foreach x in 5 7 9 11 13 15 {
	clonevar AnyEmploy`x' = Employed_Total`x'
		recode AnyEmploy`x' 2/24 = 1
	clonevar AnySearch`x' = Searching_Total`x'
		recode AnySearch`x' 2/24 = 1
	clonevar AnyDiscgd`x' = Discgd_Total`x'
		recode AnyDiscgd`x' 2/24 = 1
}
	
*Any contact 
foreach x in AnyContact ArrestEver_All JailEver_All ProbationEver_All {
	gen `x' = .
}

foreach x in 5 7 9 11 13 15 {
	replace AnyContact = 1 if ArrestEver`x' == 1 | JailEver`x' == 1 | ///
		ProbationEver`x' == 1
	replace ArrestEver_All = 1 if ArrestEver`x' == 1
	replace JailEver_All = 1 if JailEver`x' == 1
	replace ProbationEver_All = 1 if JailEver`x' == 1
}

foreach x in ArrestEver_All JailEver_All ProbationEver_All {
	replace `x' = 0 if `x' != 1 & TAS >= 1 & TAS != .
}

*Transitions
foreach x in 5 7 9 11 13 15 {
	replace TransitionEmploy`x' = .n if AnySearch`x' == 0
	replace TransitionOOLF`x' = .n if AnySearch`x' == 0
}

*Log earnings
foreach x in 7 9 11 13 15 {
	gen log_Earnings`x' = ln(EarningsPerMo_z`x' + .0001)
}


/*******************************************************************************
*********************************VARIABLES LIST*********************************
********************************************************************************
Var Type			|	 Var			  |		Var Explained
--------------------+---------------------+-------------------------------------
DV					| Discgd_Total	  	  | Total months unemployed and not searching for work
DV					| Searching_Total	  | Total months searching for work
DV (supplement)		| Employed_Total  	  | Total months employed 
--------------------+---------------------+-------------------------------------
DV					| EarningsPerMo		  | Earnings per month among employed respondents
DV					| Secondary			  | R employed on secondary market
--------------------+---------------------+-------------------------------------
IV					| WorryJob			  | Labor market insecurity (How often worry that you will not have a good job in the future?)
IV (supplement)		| FUT_Layoff		  | Labor market insecurity (In the future, how likely you to be laid off from job)
IV (supplement)		| LikelyPayWell		  | Labor market insecurity (In the future, how likely you will have a job that pays well?)
--------------------+---------------------+---------------------------------------
LEVEL 1 COVARIATES (WAVE-LEVEL)
--------------------+---------------------+-------------------------------------
Covariate			| GraduatedHS		  | R has HS degree or equivalent
Covariate			| EnrollNow			  | Enrolled in college
Covariate			| RelationshipStatus  | R married or cohabitating
Covariate			| KidsYN			  | R has children
Covariate			| UnemploymentComp	  | R receives unemployment compensation
Covariate			| Health			  | R self-reported health
Covariate			| AlcUse		 	  | R uses alcohol
Covariate			| FIN_Scale			  | Financial responsibility (independence) scale 
Covariate			| DIS_Scale			  | Everyday perceived discrimination scale
Covariate			| crash				  | Pre/post 2008 Great Recession
Covariate			| ForceOut			  | R was forced out of work
Covariate			| Risky				  | Risky behavior scale
Covariate			| AGE				  | R ages
--------------------+---------------------+-------------------------------------
LEVEL 2 COVARIATES (PERSON-LEVEL)
--------------------+---------------------+-------------------------------------
Covariate			| Sex				  | Sex of R
Covariate			| Race/ethnicity	  | R race/ethnicity
--------------------+---------------------+-------------------------------------
ADDITIONAL SENSITIVITY MEASURES (SUPPLEMENTS)
--------------------+---------------------+-------------------------------------
Covariate (L1)		| SrsArrest			  | Seriousness of last arrest
Covariate (L1)		| s_SrsArrest		  | Seriousness of last arrest (w/ no offense)
Covariate (L1)		| SrsJail			  | Seriousness of last jail stay
Covariate (L1)		| s_SrsJail			  | Seriousness of last jail stay (w/ no offense)
Covariate (L1)		| SrsProbation		  | Seriousness of last probation
Covariate (L1)		| s_SrsProbation	  | Seriousness of last probation (w/ no offense)
Covariate (L1)		| AgeLastArrest	  	  | Age at last arrest
Covariate (L1)		| AgeLastJail	  	  | Age at last jail
Covariate (L1)		| AgeLastProbation	  | Age at last probation
Covariate (L2)		| AgeAdjust			  | Age fixed at baseline
--------------------+---------------------+-------------------------------------
*******************************************************************************/

	

***
*PERSON-MEAN CENTERING CONTINUOUS LEVEL 1 COVARIATES
***
	// grand-mean centered supplements calculated later

foreach x in WorryJob FUT_Layoff LikelyPayWell Health FIN_Scale DIS_Scale Risky AGE {
	egen pm_`x' = rowmean(`x'5 `x'7 `x'9 `x'11 `x'13 `x'15)
	} // generating person-mean
	
foreach x in WorryJob FUT_Layoff LikelyPayWell Health FIN_Scale DIS_Scale Risky AGE {
	foreach y in 5 7 9 11 13 15 {
	gen pmc_`x'`y' = `x'`y' - pm_`x'
	}
	} // generating person-mean centered values
	
foreach x in 5 7 9 11 13 15 {
	gen AgeAdjust`x' = AGE5
	} // fixing age at baseline (supplement)


	
***
*CREATING LAGGED MEASURES
***
foreach x in 7 9 11 13 15 {
	local j = `x' - 2
	*Contact
	gen ArrestEver_L1`x' = ArrestEver`j'
	gen JailEver_L1`x' = JailEver`j'
	gen ProbationEver_L1`x' = ProbationEver`j'
	
	*Labor market insecurity
	gen WorryJob_L1`x' = WorryJob`j'	
	gen FUT_Layoff_L1`x' = FUT_Layoff`j'	
	gen LikelyPayWell_L1`x' = LikelyPayWell`j'	
	
	*Covariates
	gen GraduatedHS_L1`x' =  GraduatedHS`j'		
	gen EnrollNow_L1`x' = EnrollNow`j'	
	gen Relationship_L1`x' = RelationshipStatus`j'	
	gen Kids_L1`x' = KidsYN`j'	
	gen UnemploymentComp_L1`x' = UnemploymentComp`j'	
	gen Health_L1`x' = Health`j'	
	gen AlcUse_L1`x' = AlcUse`j'	
	gen FINScale_L1`x' = FIN_Scale`j'	
	gen DISScale_L1`x' = DIS_Scale`j'	
	gen Crash_L1`x' = crash`j'	
	gen ForceOut_L1`x' = ForceOut`j'	
	gen Risky_L1`x' = Risky`j'	
	gen AGE_L1`x' = AGE`j'
	
	*Supplemental covariates
	gen SrsArrest_L1`x' = SrsArrest`j'	
	gen s_SrsArrest_L1`x' = s_SrsArrest`j'	
	gen SrsJail_L1`x' = SrsJail`j'	
	gen s_SrsJail_L1`x' = s_SrsJail`j'
	gen SrsProbation_L1`x' = SrsProbation`j'
	gen s_SrsProbation_L1`x' = s_SrsProbation`j'
	gen AgeLastArrest_L1`x' = AgeLastArrest`j'
	gen AgeLastJail_L1`x' = AgeLastJail`j'
	gen AgeLastProbation_L1`x' = AgeLastProbation`j'
	
	*Person-mean centered values
	gen WorryJob_L1c`x' = pmc_WorryJob`j'
	gen FUT_Layoff_L1c`x' = pmc_FUT_Layoff`j'
	gen LikelyPayWell_L1c`x' = pmc_LikelyPayWell`j'
	gen Health_L1c`x' = pmc_Health`j'
	gen FINScale_L1c`x' = pmc_FIN_Scale`j'
	gen DISScale_L1c`x' = pmc_DIS_Scale`j'
	gen Risky_L1c`x' = pmc_Risky`j'
	gen AGE_L1c`x' = pmc_AGE`j'
	
}

	
***
*VALID WAVE AND CONSECUTIVE WAVE ANALYSIS
***
clonevar TAScheck = TAS 
replace TAScheck = 0 if TAS == .

tab TAScheck, m
/*===============================================
 Sum of All |
  TAS Flags |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |        670       18.80       18.80
          1 |        520       14.59       33.40
          2 |        557       15.63       49.03
          3 |        576       16.17       65.20
          4 |        796       22.34       87.54
          5 |        444       12.46      100.00
------------+-----------------------------------
      Total |      3,563      100.00
===============================================*/
	codebook ParticipantID // 3,563 (total unique persons)
	display 3563*6 // 21,378 (total possible person-waves)
	display 520+2*557+3*576+4*796+5*444 // 8,766 (total available person-waves)
	codebook ParticipantID if TAScheck>=1 & TAScheck!=. // 2,893 (total unique persons with any valid data)
		// 670 persons without any valid TAS data
	display 3563-670-520 // 2,373 (persons with at least two waves of data)

gen consec = .
	foreach x in 7 9 11 13 15 {
		local j = `x' - 2
		replace consec = 1 if TAS`x'==1 & TAS`j'==1
		}
tab consec if TAScheck>=1 & TAScheck!=.
	// 2,273 with two consecutive waves of data at any point
	display 2373-2273
		// 100 persons without consecutive wave data
	
tab TAScheck if consec==1 & TAScheck>=1 & TAScheck!=.
/*===============================================
 Sum of All |
  TAS Flags |      Freq.     Percent        Cum.
------------+-----------------------------------
          2 |        462       20.33       20.33
          3 |        571       25.12       45.45
          4 |        796       35.02       80.47
          5 |        444       19.53      100.00
------------+-----------------------------------
      Total |      2,273      100.00
===============================================*/
display 2*462+3*571+4*796+5*444 // 8041 person-wave observations among consecutive waves


***
*RESHAPING LONG
***
drop TAS TAScheck // total indicators; wave-level indicators retained

reshape long TAS OffLastArrest AGE WorryJob OCC UnemploymentComp GraduatedHS ///
	LikelyPayWell FUT_Layoff Health AlcUse AgeLastArrest AgeLastProbation ///
	OffLastProbation AgeLastJail OffLastJail FIN_Scale Risky DIS_Scale EnrollNow ///
	EarningsLY EarningsBefore RelationshipStatus KidsYN Benefits ForceOut ///
	ArrestEver ProbationEver JailEver s_OffLastArrest s_OffLastJail ///
	s_OffLastProbation Employed_Total Searching_Total Discgd_Total ///
	TransitionEmploy TransitionOOLF crash SrsArrest s_SrsArrest SrsJail ///
	s_SrsJail SrsProbation s_SrsProbation EarningsLY_z EarningsBefore_z ///
	WaveEarnings WaveEarnings_z EarningsPerMo EarningsPerMo_z AnyEmploy ///
	AnySearch AnyDiscgd pmc_WorryJob pmc_FUT_Layoff pmc_LikelyPayWell ///
	pmc_Health pmc_FIN_Scale pmc_DIS_Scale pmc_Risky pmc_AGE AgeAdjust ///
	ArrestEver_L1 JailEver_L1 ProbationEver_L1 WorryJob_L1 FUT_Layoff_L1 ///
	LikelyPayWell_L1 GraduatedHS_L1 EnrollNow_L1 Relationship_L1 Kids_L1 ///
	UnemploymentComp_L1 Health_L1 AlcUse_L1 FINScale_L1 DISScale_L1 Crash_L1 ///
	ForceOut_L1 Risky_L1 AGE_L1 SrsArrest_L1 s_SrsArrest_L1 SrsJail_L1 ///
	s_SrsJail_L1 SrsProbation_L1 s_SrsProbation_L1 AgeLastArrest_L1 ///
	AgeLastJail_L1 AgeLastProbation_L1 WorryJob_L1c FUT_Layoff_L1c ///
	LikelyPayWell_L1c Health_L1c FINScale_L1c DISScale_L1c Risky_L1c AGE_L1c ///
	log_Earnings, i(ParticipantID) j(wave)
	

	

****
**MERGING SECONDARY MARKET INDICATORS
****

cd "E:\[Anonymized]\Job Search\New Data 8.1.23"
do 2010OCC_Occupation.do

clonevar Secondary = occupation 
	replace Secondary = .n if TAS != 1
	
***
*GRAND-MEAN CENTERING LEVEL 1 VARIABLES
***	
foreach x in WorryJob_L1 FUT_Layoff_L1 LikelyPayWell_L1 Health_L1 FINScale_L1 ///
	DISScale_L1 Risky_L1 AGE_L1 {
		egen gm_`x' = mean(`x')
} // generating grand mean

foreach x in WorryJob_L1 FUT_Layoff_L1 LikelyPayWell_L1 Health_L1 FINScale_L1 ///
	DISScale_L1 Risky_L1 AGE_L1 {
		gen `x'gmc = `x' - gm_`x'
} // generating grand mean centered values


***
*LABELING AMBIGUOUS VALUES
***	

label define arrest 0"Not arrested" 1"Arrested"
	foreach x in ArrestEver ArrestEver_All ArrestEver_L1 {
		label value `x' arrest 
	}
	
label define jail 0"Not jailed" 1"Jailed"
	foreach x in JailEver JailEver_All JailEver_L1 {
		label value `x' jail
	}
	
label define probation 0"No probation history" 1"Probation history"
	foreach x in ProbationEver ProbationEver_All ProbationEver_L1 {
		label value `x' probation
	}

foreach x in RelationshipStatus Relationship_L1 {
	label value `x' mar
}

foreach x in GraduatedHS GraduatedHS_L1 {
	label value `x' highschool
}

foreach x in s_SrsArrest s_SrsJail s_SrsProbation s_SrsArrest_L1 s_SrsJail_L1 s_SrsProbation_L1 {
	label value `x' soffcat2
}


log close
cls



********************************************************************************
***************************  DESCRIPTIVE STATISTICS  ***************************
********************************************************************************

log using "E:\[Anonymized]\Job Search\LMParticipation_PublicFiles\Log Output\SECTION 4 - Descriptive Statistics", ///
	text replace

*Macros
global state Employed_Total Searching_Total Discgd_Total
global contact ArrestEver_L1 JailEver_L1 ProbationEver_L1
global control GraduatedHS EnrollNow RelationshipStatus KidsYN UnemploymentComp ///
	Health AlcUse FIN_Scale DIS_Scale crash ForceOut Risky AGE
global l1control GraduatedHS_L1 EnrollNow_L1 Relationship_L1 Kids_L1 ///
	UnemploymentComp_L1 Health_L1 AlcUse_L1 FINScale_L1 DISScale_L1 Crash_L1 ///
	ForceOut_L1 Risky_L1 AGE_L1
global l1controlpmc GraduatedHS_L1 EnrollNow_L1 Relationship_L1 Kids_L1 ///
	UnemploymentComp_L1 Health_L1c AlcUse_L1 FINScale_L1c DISScale_L1c Crash_L1 ///
	ForceOut_L1 Risky_L1c AGE_L1c
global l2control Sex Race


*Assessing sample of analysis
reg Searching_Total if consec == 1, cluster(ParticipantID)

reg Searching_Total $l1control if consec == 1, cluster(ParticipantID)

reg Searching_Total $l1control $l2control if consec == 1, cluster(ParticipantID)

reg Searching_Total $l1control $l2control $contact if consec == 1, cluster(ParticipantID)

reg Searching_Total $l1control $l2control $contact WorryJob_L1 if consec == 1, cluster(ParticipantID)


reg Searching_Total WorryJob_L1 $contact $l1control $l2control, cluster(ParticipantID)
	gen sample = e(sample)
		replace sample = . if sample != 1 & TAS == .
	
	/* Sample of analysis
		0 = Not in sample but wave is valid
		1 = In sample
	*/
	
	tab sample

	
*Missingness
misstable sum $state WorryJob_L1 $contact $l1control $l2control if sample != .
misstable pattern $state WorryJob_L1 $contact $l1control $l2control if sample != .

foreach x in $state WorryJob_L1 Health_L1 FINScale_L1 DISScale_L1 Risky_L1 AGE_L1 {
	ttest `x', by(sample)
}

foreach x in $contact GraduatedHS_L1 EnrollNow_L1 Relationship_L1 Kids_L1 ///
	UnemploymentComp_L1 AlcUse_L1 Crash_L1 ForceOut_L1 Sex Race {
		tab `x' sample, col chi
}


*Descriptive values
sum $state WorryJob_L1 Health_L1 FINScale_L1 DISScale_L1 Risky_L1 AGE_L1 ///
	if sample == 1
tab1 $contact GraduatedHS_L1 EnrollNow_L1 Relationship_L1 Kids_L1 ///
	UnemploymentComp_L1 AlcUse_L1 Crash_L1 ForceOut_L1 ///
	if sample == 1
	
	bysort ParticipantID: egen sample_ever = max(sample)
		// to accurately assess person-level variables
tab1 Sex Race if sample_ever == 1 & wave == 5
	// only need to assess based on sample inclusion (ever) and one wave of data


*Correlations
corr $state WorryJob_L1 $contact $l1control $l2control if sample == 1

log close
cls



********************************************************************************
********************************* MAIN MODELS **********************************
********************************************************************************

log using "E:\[Anonymized]\Job Search\LMParticipation_PublicFiles\Log Output\SECTION 5 - Main Models", ///
	text replace

*Macros for Models
global state Employed_Total Searching_Total Discgd_Total
global contact ArrestEver_L1 JailEver_L1 ProbationEver_L1
global l1control i.GraduatedHS_L1 EnrollNow_L1 Relationship_L1 Kids_L1 ///
	UnemploymentComp_L1 Health_L1 AlcUse_L1 FINScale_L1 DISScale_L1 Crash_L1 ///
	ForceOut_L1 Risky_L1 AGE_L1
global l1controlpmc i.GraduatedHS_L1 EnrollNow_L1 Relationship_L1 Kids_L1 ///
	UnemploymentComp_L1 Health_L1c AlcUse_L1 FINScale_L1c DISScale_L1c Crash_L1 ///
	ForceOut_L1 Risky_L1c AGE_L1c
global l2control Sex i.Race


****
**LABOR MARKET INSECURITY
****

**Arrest
mepoisson WorryJob ArrestEver_L1 if sample == 1 || ParticipantID: // bivariate
mepoisson WorryJob ArrestEver_L1 $l1controlpmc $l2control  if sample == 1 || ParticipantID: // multivariate

**Jail
mepoisson WorryJob JailEver_L1 if sample == 1 || ParticipantID: // bivariate
mepoisson WorryJob JailEver_L1 $l1controlpmc $l2control  if sample == 1 || ParticipantID: // multivariate

**Probation
mepoisson WorryJob ProbationEver_L1 if sample == 1 || ParticipantID: // bivariate
mepoisson WorryJob ProbationEver_L1 $l1controlpmc $l2control  if sample == 1 || ParticipantID: // multivariate



****
**TIME OUT OF THE LABOR FORCE
****

**Arrest
mepoisson Discgd_Total WorryJob_L1c pm_WorryJob if sample == 1 || ParticipantID: // bivariate
mepoisson Discgd_Total ArrestEver_L1 if sample == 1 || ParticipantID: // bivariate
mepoisson Discgd_Total WorryJob_L1c pm_WorryJob ArrestEver_L1 if sample == 1 || ParticipantID: // multivariate
mepoisson Discgd_Total WorryJob_L1c pm_WorryJob ArrestEver_L1 $l1controlpmc $l2control  if sample == 1 || ParticipantID: // multivariate

**Jail
mepoisson Discgd_Total WorryJob_L1c pm_WorryJob if sample == 1 || ParticipantID: // bivariate
mepoisson Discgd_Total JailEver_L1 if sample == 1 || ParticipantID: // bivariate
mepoisson Discgd_Total WorryJob_L1c pm_WorryJob JailEver_L1 if sample == 1 || ParticipantID: // multivariate
mepoisson Discgd_Total WorryJob_L1c pm_WorryJob JailEver_L1 $l1controlpmc $l2control  if sample == 1 || ParticipantID: // multivariate

**Probation
mepoisson Discgd_Total WorryJob_L1c pm_WorryJob if sample == 1 || ParticipantID: // bivariate
mepoisson Discgd_Total ProbationEver_L1 if sample == 1 || ParticipantID: // bivariate
mepoisson Discgd_Total WorryJob_L1c pm_WorryJob ProbationEver_L1 if sample == 1 || ParticipantID: // multivariate
mepoisson Discgd_Total WorryJob_L1c pm_WorryJob ProbationEver_L1 $l1controlpmc $l2control  if sample == 1 || ParticipantID: // multivariate



****
**TIME SEARCHING FOR WORK
****

**Arrest
mepoisson Searching_Total WorryJob_L1c pm_WorryJob if sample == 1 || ParticipantID: // bivariate
mepoisson Searching_Total ArrestEver_L1 if sample == 1 || ParticipantID: // bivariate
mepoisson Searching_Total WorryJob_L1c pm_WorryJob ArrestEver_L1 if sample == 1 || ParticipantID: // multivariate
mepoisson Searching_Total WorryJob_L1c pm_WorryJob ArrestEver_L1 $l1controlpmc $l2control  if sample == 1 || ParticipantID: // multivariate

**Jail
mepoisson Searching_Total WorryJob_L1c pm_WorryJob if sample == 1 || ParticipantID: // bivariate
mepoisson Searching_Total JailEver_L1 if sample == 1 || ParticipantID: // bivariate
mepoisson Searching_Total WorryJob_L1c pm_WorryJob JailEver_L1 if sample == 1 || ParticipantID: // multivariate
mepoisson Searching_Total WorryJob_L1c pm_WorryJob JailEver_L1 $l1controlpmc $l2control  if sample == 1 || ParticipantID: // multivariate

**Probation
mepoisson Searching_Total WorryJob_L1c pm_WorryJob if sample == 1 || ParticipantID: // bivariate
mepoisson Searching_Total ProbationEver_L1 if sample == 1 || ParticipantID: // bivariate
mepoisson Searching_Total WorryJob_L1c pm_WorryJob ProbationEver_L1 if sample == 1 || ParticipantID: // multivariate
mepoisson Searching_Total WorryJob_L1c pm_WorryJob ProbationEver_L1 $l1controlpmc $l2control  if sample == 1 || ParticipantID: // multivariate



****
**JOB PLACEMENT IN SECONDARY MARKET
****

*Arrest
logit Secondary ArrestEver_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID) or
logit Secondary WorryJob_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID) or
logit Secondary ArrestEver_L1 WorryJob_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID) or
logit Secondary ArrestEver_L1 WorryJob_L1 ///
	$l1control $l2control if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID) or

*Jail
logit Secondary JailEver_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID) or
logit Secondary WorryJob_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID) or
logit Secondary JailEver_L1 WorryJob_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID) or
logit Secondary JailEver_L1 WorryJob_L1 ///
	$l1control $l2control if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID) or

*Probation
logit Secondary ProbationEver_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID) or
logit Secondary WorryJob_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID) or
logit Secondary ProbationEver_L1 WorryJob_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID) or
logit Secondary ProbationEver_L1 WorryJob_L1 ///
	$l1control $l2control if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID) or


****
**EARNINGS
****

*Arrest
reg log_Earnings ArrestEver_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
reg log_Earnings WorryJob_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
reg log_Earnings ArrestEver_L1 WorryJob_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
reg log_Earnings ArrestEver_L1 WorryJob_L1 ///
	$l1control $l2control if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)

*Jail
reg log_Earnings JailEver_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
reg log_Earnings WorryJob_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
reg log_Earnings JailEver_L1 WorryJob_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
reg log_Earnings JailEver_L1 WorryJob_L1 ///
	$l1control $l2control if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)

*Probation
reg log_Earnings ProbationEver_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
reg log_Earnings WorryJob_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
reg log_Earnings ProbationEver_L1 WorryJob_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
reg log_Earnings ProbationEver_L1 WorryJob_L1 ///
	$l1control $l2control if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
	
log close
cls



		
********************************************************************************
********************************************************************************
*******************  SENSITIVITY AND SUPPLEMENTAL ANALYSES  ********************
********************************************************************************
********************************************************************************		
		
log using "E:\[Anonymized]\Job Search\LMParticipation_PublicFiles\Log Output\SECTION 6 - Supplement - Single Level Models", ///
	text replace
	
*****************************************
*SUPPLEMENTAL MODELS: SINGLE LEVEL MODELS
*****************************************
*	Models specified without multilevel or random intercept values.
*	Models clustered by participant to estimate robust standard errors.
	
*Macros for Models
global state Employed_Total Searching_Total Discgd_Total
global contact ArrestEver_L1 JailEver_L1 ProbationEver_L1
global l1control i.GraduatedHS_L1 EnrollNow_L1 Relationship_L1 Kids_L1 ///
	UnemploymentComp_L1 Health_L1 AlcUse_L1 FINScale_L1 DISScale_L1 Crash_L1 ///
	ForceOut_L1 Risky_L1 AGE_L1
global l1controlpmc i.GraduatedHS_L1 EnrollNow_L1 Relationship_L1 Kids_L1 ///
	UnemploymentComp_L1 Health_L1c AlcUse_L1 FINScale_L1c DISScale_L1c Crash_L1 ///
	ForceOut_L1 Risky_L1c AGE_L1c
global l2control Sex i.Race


****
**LABOR MARKET INSECURITY
****

**Arrest
poisson WorryJob ArrestEver_L1 if sample == 1, cluster(ParticipantID) // bivariate
poisson WorryJob ArrestEver_L1 $l1control $l2control  if sample == 1, cluster(ParticipantID) // multivariate

**Jail
poisson WorryJob JailEver_L1 if sample == 1, cluster(ParticipantID) // bivariate
poisson WorryJob JailEver_L1 $l1control $l2control  if sample == 1, cluster(ParticipantID) // multivariate

**Probation
poisson WorryJob ProbationEver_L1 if sample == 1, cluster(ParticipantID) // bivariate
poisson WorryJob ProbationEver_L1 $l1control $l2control  if sample == 1, cluster(ParticipantID) // multivariate



****
**TIME OUT OF THE LABOR FORCE
****

**Arrest
poisson Discgd_Total WorryJob_L1 if sample == 1, cluster(ParticipantID) // bivariate
poisson Discgd_Total ArrestEver_L1 if sample == 1, cluster(ParticipantID) // bivariate
poisson Discgd_Total WorryJob_L1 ArrestEver_L1 if sample == 1, cluster(ParticipantID) // multivariate
poisson Discgd_Total WorryJob_L1 ArrestEver_L1 $l1control $l2control  if sample == 1, cluster(ParticipantID) // multivariate

**Jail
poisson Discgd_Total WorryJob_L1 if sample == 1, cluster(ParticipantID) // bivariate
poisson Discgd_Total JailEver_L1 if sample == 1, cluster(ParticipantID) // bivariate
poisson Discgd_Total WorryJob_L1 JailEver_L1 if sample == 1, cluster(ParticipantID) // multivariate
poisson Discgd_Total WorryJob_L1 JailEver_L1 $l1control $l2control  if sample == 1, cluster(ParticipantID) // multivariate

**Probation
poisson Discgd_Total WorryJob_L1 if sample == 1, cluster(ParticipantID) // bivariate
poisson Discgd_Total ProbationEver_L1 if sample == 1, cluster(ParticipantID) // bivariate
poisson Discgd_Total WorryJob_L1 ProbationEver_L1 if sample == 1, cluster(ParticipantID) // multivariate
poisson Discgd_Total WorryJob_L1 ProbationEver_L1 $l1control $l2control  if sample == 1, cluster(ParticipantID) // multivariate



****
**TIME SEARCHING FOR WORK
****

**Arrest
poisson Searching_Total WorryJob_L1 if sample == 1, cluster(ParticipantID) // bivariate
poisson Searching_Total ArrestEver_L1 if sample == 1, cluster(ParticipantID) // bivariate
poisson Searching_Total WorryJob_L1 ArrestEver_L1 if sample == 1, cluster(ParticipantID) // multivariate
poisson Searching_Total WorryJob_L1 ArrestEver_L1 $l1control $l2control  if sample == 1, cluster(ParticipantID) // multivariate

**Jail
poisson Searching_Total WorryJob_L1 if sample == 1, cluster(ParticipantID) // bivariate
poisson Searching_Total JailEver_L1 if sample == 1, cluster(ParticipantID) // bivariate
poisson Searching_Total WorryJob_L1 JailEver_L1 if sample == 1, cluster(ParticipantID) // multivariate
poisson Searching_Total WorryJob_L1 JailEver_L1 $l1control $l2control  if sample == 1, cluster(ParticipantID) // multivariate

**Probation
poisson Searching_Total WorryJob_L1 if sample == 1, cluster(ParticipantID) // bivariate
poisson Searching_Total ProbationEver_L1 if sample == 1, cluster(ParticipantID) // bivariate
poisson Searching_Total WorryJob_L1 ProbationEver_L1 if sample == 1, cluster(ParticipantID) // multivariate
poisson Searching_Total WorryJob_L1 ProbationEver_L1 $l1control $l2control  if sample == 1, cluster(ParticipantID) // multivariate

log close
cls



********************************************************************************
********************************************************************************


log using "E:\[Anonymized]\Job Search\LMParticipation_PublicFiles\Log Output\SECTION 7 - Supplement - Negative Binomial Models", ///
	text replace

*NOTE: Code logged here represents attempted multilevel negative binomial distribution
*assessment. Most models did not converge and evidenced poor model fit when convergence
*was achieved. We do not advise additional interpretation of the code presented here.


/***************************************************
*SUPPLEMENTAL MODELS: NEGATIVE BINOMIAL DISTRIBUTION
****************************************************
*	Models specified as multilevel with negative binomial distribution.

*Macros for Models
global state Employed_Total Searching_Total Discgd_Total
global contact ArrestEver_L1 JailEver_L1 ProbationEver_L1
global l1control i.GraduatedHS_L1 EnrollNow_L1 Relationship_L1 Kids_L1 ///
	UnemploymentComp_L1 Health_L1 AlcUse_L1 FINScale_L1 DISScale_L1 Crash_L1 ///
	ForceOut_L1 Risky_L1 AGE_L1
global l1controlpmc i.GraduatedHS_L1 EnrollNow_L1 Relationship_L1 Kids_L1 ///
	UnemploymentComp_L1 Health_L1c AlcUse_L1 FINScale_L1c DISScale_L1c Crash_L1 ///
	ForceOut_L1 Risky_L1c AGE_L1c
global l2control Sex i.Race
	
****
**LABOR MARKET INSECURITY
****

**Arrest
menbreg WorryJob ArrestEver_L1 if sample == 1 || ParticipantID: // bivariate
menbreg WorryJob ArrestEver_L1 $l1controlpmc $l2control  if sample == 1 || ParticipantID: // multivariate

**Jail
menbreg WorryJob JailEver_L1 if sample == 1 || ParticipantID: // bivariate
menbreg WorryJob JailEver_L1 $l1controlpmc $l2control  if sample == 1 || ParticipantID: // multivariate

**Probation
menbreg WorryJob ProbationEver_L1 if sample == 1 || ParticipantID: // bivariate
menbreg WorryJob ProbationEver_L1 $l1controlpmc $l2control  if sample == 1 || ParticipantID: // multivariate



****
**TIME OUT OF THE LABOR FORCE
****

**Arrest
menbreg Discgd_Total WorryJob_L1 if sample == 1 || ParticipantID: // bivariate
menbreg Discgd_Total ArrestEver_L1 if sample == 1 || ParticipantID: // bivariate
menbreg Discgd_Total WorryJob_L1 ArrestEver_L1 if sample == 1 || ParticipantID: // multivariate
menbreg Discgd_Total WorryJob_L1 ArrestEver_L1 $l1controlpmc $l2control  if sample == 1 || ParticipantID: // multivariate

**Jail
menbreg Discgd_Total WorryJob_L1 if sample == 1 || ParticipantID: // bivariate
menbreg Discgd_Total JailEver_L1 if sample == 1 || ParticipantID: // bivariate
menbreg Discgd_Total WorryJob_L1 JailEver_L1 if sample == 1 || ParticipantID: // multivariate
menbreg Discgd_Total WorryJob_L1 JailEver_L1 $l1controlpmc $l2control  if sample == 1 || ParticipantID: // multivariate

**Probation
menbreg Discgd_Total WorryJob_L1 if sample == 1 || ParticipantID: // bivariate
menbreg Discgd_Total ProbationEver_L1 if sample == 1 || ParticipantID: // bivariate
menbreg Discgd_Total WorryJob_L1 ProbationEver_L1 if sample == 1 || ParticipantID: // multivariate
menbreg Discgd_Total WorryJob_L1 ProbationEver_L1 $l1controlpmc $l2control  if sample == 1 || ParticipantID: // multivariate



****
**TIME SEARCHING FOR WORK
****

**Arrest
menbreg Searching_Total WorryJob_L1 if sample == 1 || ParticipantID: // bivariate
menbreg Searching_Total ArrestEver_L1 if sample == 1 || ParticipantID: // bivariate
menbreg Searching_Total WorryJob_L1 ArrestEver_L1 if sample == 1 || ParticipantID: // multivariate
menbreg Searching_Total WorryJob_L1 ArrestEver_L1 $l1controlpmc $l2control  if sample == 1 || ParticipantID: // multivariate

**Jail
menbreg Searching_Total WorryJob_L1 if sample == 1 || ParticipantID: // bivariate
menbreg Searching_Total JailEver_L1 if sample == 1 || ParticipantID: // bivariate
menbreg Searching_Total WorryJob_L1 JailEver_L1 if sample == 1 || ParticipantID: // multivariate
menbreg Searching_Total WorryJob_L1 JailEver_L1 $l1controlpmc $l2control  if sample == 1 || ParticipantID: // multivariate

**Probation
menbreg Searching_Total WorryJob_L1 if sample == 1 || ParticipantID: // bivariate
menbreg Searching_Total ProbationEver_L1 if sample == 1 || ParticipantID: // bivariate
menbreg Searching_Total WorryJob_L1 ProbationEver_L1 if sample == 1 || ParticipantID: // multivariate
menbreg Searching_Total WorryJob_L1 ProbationEver_L1 $l1controlpmc $l2control  if sample == 1 || ParticipantID: // multivariate	
*/

log close
cls


********************************************************************************
********************************************************************************


log using "E:\[Anonymized]\Job Search\LMParticipation_PublicFiles\Log Output\SECTION 8 - Supplement - Time Employed Outcome", ///
	text replace	
*********************************
*SUPPLEMENTAL OUTCOME: EMPLOYMENT
*********************************
*	Estimates mirror those in text.
*	Outcome represents total number of months employed in a recall period.

*Macros for Models
global state Employed_Total Searching_Total Discgd_Total
global contact ArrestEver_L1 JailEver_L1 ProbationEver_L1
global l1control i.GraduatedHS_L1 EnrollNow_L1 Relationship_L1 Kids_L1 ///
	UnemploymentComp_L1 Health_L1 AlcUse_L1 FINScale_L1 DISScale_L1 Crash_L1 ///
	ForceOut_L1 Risky_L1 AGE_L1
global l1controlpmc i.GraduatedHS_L1 EnrollNow_L1 Relationship_L1 Kids_L1 ///
	UnemploymentComp_L1 Health_L1c AlcUse_L1 FINScale_L1c DISScale_L1c Crash_L1 ///
	ForceOut_L1 Risky_L1c AGE_L1c
global l2control Sex i.Race

**Arrest
mepoisson Employed_Total WorryJob_L1 if sample == 1 || ParticipantID: // bivariate
mepoisson Employed_Total ArrestEver_L1 if sample == 1 || ParticipantID: // bivariate
mepoisson Employed_Total WorryJob_L1 ArrestEver_L1 if sample == 1 || ParticipantID: // multivariate
mepoisson Employed_Total WorryJob_L1 ArrestEver_L1 $l1controlpmc $l2control  if sample == 1 || ParticipantID: // multivariate

**Jail
mepoisson Employed_Total WorryJob_L1 if sample == 1 || ParticipantID: // bivariate
mepoisson Employed_Total JailEver_L1 if sample == 1 || ParticipantID: // bivariate
mepoisson Employed_Total WorryJob_L1 JailEver_L1 if sample == 1 || ParticipantID: // multivariate
mepoisson Employed_Total WorryJob_L1 JailEver_L1 $l1controlpmc $l2control  if sample == 1 || ParticipantID: // multivariate

**Probation
mepoisson Employed_Total WorryJob_L1 if sample == 1 || ParticipantID: // bivariate
mepoisson Employed_Total ProbationEver_L1 if sample == 1 || ParticipantID: // bivariate
mepoisson Employed_Total WorryJob_L1 ProbationEver_L1 if sample == 1 || ParticipantID: // multivariate
mepoisson Employed_Total WorryJob_L1 ProbationEver_L1 $l1controlpmc $l2control  if sample == 1 || ParticipantID: // multivariate

log close
cls


********************************************************************************
********************************************************************************


log using "E:\[Anonymized]\Job Search\LMParticipation_PublicFiles\Log Output\SECTION 9 - Supplement - Untransformed Earnings Outcome", ///
	text replace
****************************************************
*SUPPLEMENTAL MODELS: UNTRANSFORMED EARNINGS OUTCOME
****************************************************
*	Earnings models without natural log transformation.

*Macros for Models
global state Employed_Total Searching_Total Discgd_Total
global contact ArrestEver_L1 JailEver_L1 ProbationEver_L1
global l1control i.GraduatedHS_L1 EnrollNow_L1 Relationship_L1 Kids_L1 ///
	UnemploymentComp_L1 Health_L1 AlcUse_L1 FINScale_L1 DISScale_L1 Crash_L1 ///
	ForceOut_L1 Risky_L1 AGE_L1
global l1controlpmc i.GraduatedHS_L1 EnrollNow_L1 Relationship_L1 Kids_L1 ///
	UnemploymentComp_L1 Health_L1c AlcUse_L1 FINScale_L1c DISScale_L1c Crash_L1 ///
	ForceOut_L1 Risky_L1c AGE_L1c
global l2control Sex i.Race

*Arrest
reg EarningsPerMo_z ArrestEver_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
reg EarningsPerMo_z WorryJob_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
reg EarningsPerMo_z ArrestEver_L1 WorryJob_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
reg EarningsPerMo_z ArrestEver_L1 WorryJob_L1 ///
	$l1control $l2control if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)

*Jail
reg EarningsPerMo_z JailEver_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
reg EarningsPerMo_z WorryJob_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
reg EarningsPerMo_z JailEver_L1 WorryJob_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
reg EarningsPerMo_z JailEver_L1 WorryJob_L1 ///
	$l1control $l2control if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)

*Probation
reg EarningsPerMo_z ProbationEver_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
reg EarningsPerMo_z WorryJob_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
reg EarningsPerMo_z ProbationEver_L1 WorryJob_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
reg EarningsPerMo_z ProbationEver_L1 WorryJob_L1 ///
	$l1control $l2control if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
	
log close
cls
	
	
********************************************************************************
********************************************************************************


log using "E:\[Anonymized]\Job Search\LMParticipation_PublicFiles\Log Output\SECTION 10 - Sensitivity - Alternate LMI Measures", ///
	text replace
***********************************************
*SENSITIVITY ESTIMATES: LABOR MARKET INSECURITY
***********************************************
*	Two sensitivity estimates for labor market insecurity measure:
*		In the future, how likely you to be laid off from job?
*		In the future, how likely you will have a job that pays well?
*	Estimates mirror those in text with alternative labor market insecurity measures.

*Macros for Models
global state Employed_Total Searching_Total Discgd_Total
global contact ArrestEver_L1 JailEver_L1 ProbationEver_L1
global l1control i.GraduatedHS_L1 EnrollNow_L1 Relationship_L1 Kids_L1 ///
	UnemploymentComp_L1 Health_L1 AlcUse_L1 FINScale_L1 DISScale_L1 Crash_L1 ///
	ForceOut_L1 Risky_L1 AGE_L1
global l1controlpmc i.GraduatedHS_L1 EnrollNow_L1 Relationship_L1 Kids_L1 ///
	UnemploymentComp_L1 Health_L1c AlcUse_L1 FINScale_L1c DISScale_L1c Crash_L1 ///
	ForceOut_L1 Risky_L1c AGE_L1c
global l2control Sex i.Race

****
**PERCEIVED LIKELIHOOD OF LAYOFF
****

**Arrest
mepoisson FUT_Layoff ArrestEver_L1 if sample == 1 || ParticipantID: // bivariate
mepoisson FUT_Layoff ArrestEver_L1 $l1controlpmc $l2control  if sample == 1 || ParticipantID: // multivariate

**Jail
mepoisson FUT_Layoff JailEver_L1 if sample == 1 || ParticipantID: // bivariate
mepoisson FUT_Layoff JailEver_L1 $l1controlpmc $l2control  if sample == 1 || ParticipantID: // multivariate

**Probation
mepoisson FUT_Layoff ProbationEver_L1 if sample == 1 || ParticipantID: // bivariate
mepoisson FUT_Layoff ProbationEver_L1 $l1controlpmc $l2control  if sample == 1 || ParticipantID: // multivariate



****
**TIME OUT OF THE LABOR FORCE
****

**Arrest
mepoisson Discgd_Total FUT_Layoff_L1c pm_FUT_Layoff if sample == 1 || ParticipantID: // bivariate
mepoisson Discgd_Total FUT_Layoff_L1c pm_FUT_Layoff ArrestEver_L1 if sample == 1 || ParticipantID: // multivariate
mepoisson Discgd_Total FUT_Layoff_L1c pm_FUT_Layoff ArrestEver_L1 $l1controlpmc $l2control  if sample == 1 || ParticipantID: // multivariate

**Jail
mepoisson Discgd_Total FUT_Layoff_L1c pm_FUT_Layoff if sample == 1 || ParticipantID: // bivariate
mepoisson Discgd_Total FUT_Layoff_L1c pm_FUT_Layoff JailEver_L1 if sample == 1 || ParticipantID: // multivariate
mepoisson Discgd_Total FUT_Layoff_L1c pm_FUT_Layoff JailEver_L1 $l1controlpmc $l2control  if sample == 1 || ParticipantID: // multivariate

**Probation
mepoisson Discgd_Total FUT_Layoff_L1c pm_FUT_Layoff if sample == 1 || ParticipantID: // bivariate
mepoisson Discgd_Total FUT_Layoff_L1c pm_FUT_Layoff ProbationEver_L1 if sample == 1 || ParticipantID: // multivariate
mepoisson Discgd_Total FUT_Layoff_L1c pm_FUT_Layoff ProbationEver_L1 $l1controlpmc $l2control  if sample == 1 || ParticipantID: // multivariate



****
**TIME SEARCHING FOR WORK
****

**Arrest
mepoisson Searching_Total FUT_Layoff_L1c pm_FUT_Layoff if sample == 1 || ParticipantID: // bivariate
mepoisson Searching_Total FUT_Layoff_L1c pm_FUT_Layoff ArrestEver_L1 if sample == 1 || ParticipantID: // multivariate
mepoisson Searching_Total FUT_Layoff_L1c pm_FUT_Layoff ArrestEver_L1 $l1controlpmc $l2control  if sample == 1 || ParticipantID: // multivariate

**Jail
mepoisson Searching_Total FUT_Layoff_L1c pm_FUT_Layoff if sample == 1 || ParticipantID: // bivariate
mepoisson Searching_Total FUT_Layoff_L1c pm_FUT_Layoff JailEver_L1 if sample == 1 || ParticipantID: // multivariate
mepoisson Searching_Total FUT_Layoff_L1c pm_FUT_Layoff JailEver_L1 $l1controlpmc $l2control  if sample == 1 || ParticipantID: // multivariate

**Probation
mepoisson Searching_Total FUT_Layoff_L1c pm_FUT_Layoff if sample == 1 || ParticipantID: // bivariate
mepoisson Searching_Total FUT_Layoff_L1c pm_FUT_Layoff ProbationEver_L1 if sample == 1 || ParticipantID: // multivariate
mepoisson Searching_Total FUT_Layoff_L1c pm_FUT_Layoff ProbationEver_L1 $l1controlpmc $l2control  if sample == 1 || ParticipantID: // multivariate



****
**JOB PLACEMENT IN SECONDARY MARKET
****

*Arrest
logit Secondary FUT_Layoff_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
logit Secondary ArrestEver_L1 FUT_Layoff_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
logit Secondary ArrestEver_L1 FUT_Layoff_L1 ///
	$l1control $l2control if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)

*Jail
logit Secondary FUT_Layoff_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
logit Secondary JailEver_L1 FUT_Layoff_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
logit Secondary JailEver_L1 FUT_Layoff_L1 ///
	$l1control $l2control if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)

*Probation
logit Secondary FUT_Layoff_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
logit Secondary ProbationEver_L1 FUT_Layoff_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
logit Secondary ProbationEver_L1 FUT_Layoff_L1 ///
	$l1control $l2control if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)


****
**EARNINGS
****

*Arrest
reg log_Earnings FUT_Layoff_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
reg log_Earnings ArrestEver_L1 FUT_Layoff_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
reg log_Earnings ArrestEver_L1 FUT_Layoff_L1 ///
	$l1control $l2control if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)

*Jail
reg log_Earnings FUT_Layoff_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
reg log_Earnings JailEver_L1 FUT_Layoff_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
reg log_Earnings JailEver_L1 FUT_Layoff_L1 ///
	$l1control $l2control if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)

*Probation
reg log_Earnings FUT_Layoff_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
reg log_Earnings ProbationEver_L1 FUT_Layoff_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
reg log_Earnings ProbationEver_L1 FUT_Layoff_L1 ///
	$l1control $l2control if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)

	
	
	
	
****
**PERCEIVED LIKELIHOOD OF A JOB THAT PAYS WELL
****

**Arrest
mepoisson LikelyPayWell ArrestEver_L1 if sample == 1 || ParticipantID: // bivariate
mepoisson LikelyPayWell ArrestEver_L1 $l1controlpmc $l2control  if sample == 1 || ParticipantID: // multivariate

**Jail
mepoisson LikelyPayWell JailEver_L1 if sample == 1 || ParticipantID: // bivariate
mepoisson LikelyPayWell JailEver_L1 $l1controlpmc $l2control  if sample == 1 || ParticipantID: // multivariate

**Probation
mepoisson LikelyPayWell ProbationEver_L1 if sample == 1 || ParticipantID: // bivariate
mepoisson LikelyPayWell ProbationEver_L1 $l1controlpmc $l2control  if sample == 1 || ParticipantID: // multivariate



****
**TIME OUT OF THE LABOR FORCE
****

**Arrest
mepoisson Discgd_Total LikelyPayWell_L1c if sample == 1 || ParticipantID: // bivariate
mepoisson Discgd_Total LikelyPayWell_L1c ArrestEver_L1 if sample == 1 || ParticipantID: // multivariate
mepoisson Discgd_Total LikelyPayWell_L1c ArrestEver_L1 $l1controlpmc $l2control  if sample == 1 || ParticipantID: // multivariate

**Jail
mepoisson Discgd_Total LikelyPayWell_L1c if sample == 1 || ParticipantID: // bivariate
mepoisson Discgd_Total LikelyPayWell_L1c JailEver_L1 if sample == 1 || ParticipantID: // multivariate
mepoisson Discgd_Total LikelyPayWell_L1c JailEver_L1 $l1controlpmc $l2control  if sample == 1 || ParticipantID: // multivariate

**Probation
mepoisson Discgd_Total LikelyPayWell_L1c if sample == 1 || ParticipantID: // bivariate
mepoisson Discgd_Total LikelyPayWell_L1c ProbationEver_L1 if sample == 1 || ParticipantID: // multivariate
mepoisson Discgd_Total LikelyPayWell_L1c ProbationEver_L1 $l1controlpmc $l2control  if sample == 1 || ParticipantID: // multivariate



****
**TIME SEARCHING FOR WORK
****

**Arrest
mepoisson Searching_Total LikelyPayWell_L1c if sample == 1 || ParticipantID: // bivariate
mepoisson Searching_Total LikelyPayWell_L1c ArrestEver_L1 if sample == 1 || ParticipantID: // multivariate
mepoisson Searching_Total LikelyPayWell_L1c ArrestEver_L1 $l1controlpmc $l2control  if sample == 1 || ParticipantID: // multivariate

**Jail
mepoisson Searching_Total LikelyPayWell_L1c if sample == 1 || ParticipantID: // bivariate
mepoisson Searching_Total LikelyPayWell_L1c JailEver_L1 if sample == 1 || ParticipantID: // multivariate
mepoisson Searching_Total LikelyPayWell_L1c JailEver_L1 $l1controlpmc $l2control  if sample == 1 || ParticipantID: // multivariate

**Probation
mepoisson Searching_Total LikelyPayWell_L1c if sample == 1 || ParticipantID: // bivariate
mepoisson Searching_Total LikelyPayWell_L1c ProbationEver_L1 if sample == 1 || ParticipantID: // multivariate
mepoisson Searching_Total LikelyPayWell_L1c ProbationEver_L1 $l1controlpmc $l2control  if sample == 1 || ParticipantID: // multivariate



****
**JOB PLACEMENT IN SECONDARY MARKET
****

*Arrest
logit Secondary LikelyPayWell_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
logit Secondary ArrestEver_L1 LikelyPayWell_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
logit Secondary ArrestEver_L1 LikelyPayWell_L1 ///
	$l1control $l2control if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)

*Jail
logit Secondary LikelyPayWell_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
logit Secondary JailEver_L1 LikelyPayWell_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
logit Secondary JailEver_L1 LikelyPayWell_L1 ///
	$l1control $l2control if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)

*Probation
logit Secondary LikelyPayWell_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
logit Secondary ProbationEver_L1 LikelyPayWell_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
logit Secondary ProbationEver_L1 LikelyPayWell_L1 ///
	$l1control $l2control if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)


****
**EARNINGS
****

*Arrest
reg log_Earnings LikelyPayWell_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
reg log_Earnings ArrestEver_L1 LikelyPayWell_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
reg log_Earnings ArrestEver_L1 LikelyPayWell_L1 ///
	$l1control $l2control if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)

*Jail
reg log_Earnings LikelyPayWell_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
reg log_Earnings JailEver_L1 LikelyPayWell_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
reg log_Earnings JailEver_L1 LikelyPayWell_L1 ///
	$l1control $l2control if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)

*Probation
reg log_Earnings LikelyPayWell_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
reg log_Earnings ProbationEver_L1 LikelyPayWell_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
reg log_Earnings ProbationEver_L1 LikelyPayWell_L1 ///
	$l1control $l2control if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
	
log close
cls
	
	
	
********************************************************************************
********************************************************************************	
	
	
log using "E:\[Anonymized]\Job Search\LMParticipation_PublicFiles\Log Output\SECTION 11 - Sensitivity - Offense Type and Recency", ///
	text replace	
************************************************************
*SENSITIVITY ESTIMATES: LAST OFFENSE AND AGE AT LAST OFFENSE
************************************************************
*	Estimates mirror those in text with addition of values representing
*		1) Severity of last offense associated with respective contact.
*		2) Age at last offense associated with respective contact.

*Macros for Models
global state Employed_Total Searching_Total Discgd_Total
global contact ArrestEver_L1 JailEver_L1 ProbationEver_L1
global l1control i.GraduatedHS_L1 EnrollNow_L1 Relationship_L1 Kids_L1 ///
	UnemploymentComp_L1 Health_L1 AlcUse_L1 FINScale_L1 DISScale_L1 Crash_L1 ///
	ForceOut_L1 Risky_L1 AGE_L1
global l1controlpmc i.GraduatedHS_L1 EnrollNow_L1 Relationship_L1 Kids_L1 ///
	UnemploymentComp_L1 Health_L1c AlcUse_L1 FINScale_L1c DISScale_L1c Crash_L1 ///
	ForceOut_L1 Risky_L1c AGE_L1c
global l2control Sex i.Race


* 1) SEVERITY OF LAST OFFENSE

****
**LABOR MARKET INSECURITY
****

**Arrest
mepoisson WorryJob i.s_SrsArrest_L1 if sample == 1 || ParticipantID: // bivariate
mepoisson WorryJob i.s_SrsArrest_L1 $l1controlpmc $l2control  if sample == 1 || ParticipantID: // multivariate

**Jail
mepoisson WorryJob i.s_SrsJail_L1 if sample == 1 || ParticipantID: // bivariate
mepoisson WorryJob i.s_SrsJail_L1 $l1controlpmc $l2control  if sample == 1 || ParticipantID: // multivariate

**Probation
mepoisson WorryJob i.s_SrsProbation_L1 if sample == 1 || ParticipantID: // bivariate
mepoisson WorryJob i.s_SrsProbation_L1 $l1controlpmc $l2control  if sample == 1 || ParticipantID: // multivariate



****
**TIME OUT OF THE LABOR FORCE
****

**Arrest
mepoisson Discgd_Total i.s_SrsArrest_L1 if sample == 1 || ParticipantID: // bivariate
mepoisson Discgd_Total WorryJob_L1c pm_WorryJob i.s_SrsArrest_L1 if sample == 1 || ParticipantID: // multivariate
mepoisson Discgd_Total WorryJob_L1c pm_WorryJob i.s_SrsArrest_L1 $l1controlpmc $l2control  if sample == 1 || ParticipantID: // multivariate

**Jail
mepoisson Discgd_Total i.s_SrsJail_L1 if sample == 1 || ParticipantID: // bivariate
mepoisson Discgd_Total WorryJob_L1c pm_WorryJob i.s_SrsJail_L1 if sample == 1 || ParticipantID: // multivariate
mepoisson Discgd_Total WorryJob_L1c pm_WorryJob i.s_SrsJail_L1 $l1controlpmc $l2control  if sample == 1 || ParticipantID: // multivariate

**Probation
mepoisson Discgd_Total i.s_SrsProbation_L1 if sample == 1 || ParticipantID: // bivariate
mepoisson Discgd_Total WorryJob_L1c pm_WorryJob i.s_SrsProbation_L1 if sample == 1 || ParticipantID: // multivariate
mepoisson Discgd_Total WorryJob_L1c pm_WorryJob i.s_SrsProbation_L1 $l1controlpmc $l2control  if sample == 1 || ParticipantID: // multivariate



****
**TIME SEARCHING FOR WORK
****

**Arrest
mepoisson Searching_Total i.s_SrsArrest_L1 if sample == 1 || ParticipantID: // bivariate
mepoisson Searching_Total WorryJob_L1c pm_WorryJob i.s_SrsArrest_L1 if sample == 1 || ParticipantID: // multivariate
mepoisson Searching_Total WorryJob_L1c pm_WorryJob i.s_SrsArrest_L1 $l1controlpmc $l2control  if sample == 1 || ParticipantID: // multivariate

**Jail
mepoisson Searching_Total i.s_SrsJail_L1 if sample == 1 || ParticipantID: // bivariate
mepoisson Searching_Total WorryJob_L1c pm_WorryJob i.s_SrsJail_L1 if sample == 1 || ParticipantID: // multivariate
mepoisson Searching_Total WorryJob_L1c pm_WorryJob i.s_SrsJail_L1 $l1controlpmc $l2control  if sample == 1 || ParticipantID: // multivariate

**Probation
mepoisson Searching_Total i.s_SrsProbation_L1 if sample == 1 || ParticipantID: // bivariate
mepoisson Searching_Total WorryJob_L1c pm_WorryJob i.s_SrsProbation_L1 if sample == 1 || ParticipantID: // multivariate
mepoisson Searching_Total WorryJob_L1c pm_WorryJob i.s_SrsProbation_L1 $l1controlpmc $l2control  if sample == 1 || ParticipantID: // multivariate



****
**JOB PLACEMENT IN SECONDARY MARKET
****

*Arrest
logit Secondary i.s_SrsArrest_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
logit Secondary i.s_SrsArrest_L1 WorryJob_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
logit Secondary i.s_SrsArrest_L1 WorryJob_L1 ///
	$l1control $l2control if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)

*Jail
logit Secondary i.s_SrsJail_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
logit Secondary i.s_SrsJail_L1 WorryJob_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
logit Secondary i.s_SrsJail_L1 WorryJob_L1 ///
	$l1control $l2control if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)

*Probation
logit Secondary i.s_SrsProbation_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
logit Secondary i.s_SrsProbation_L1 WorryJob_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
logit Secondary i.s_SrsProbation_L1 WorryJob_L1 ///
	$l1control $l2control if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)


****
**EARNINGS
****

*Arrest
reg log_Earnings i.s_SrsArrest_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
reg log_Earnings i.s_SrsArrest_L1 WorryJob_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
reg log_Earnings i.s_SrsArrest_L1 WorryJob_L1 ///
	$l1control $l2control if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)

*Jail
reg log_Earnings i.s_SrsJail_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
reg log_Earnings i.s_SrsJail_L1 WorryJob_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
reg log_Earnings i.s_SrsJail_L1 WorryJob_L1 ///
	$l1control $l2control if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)

*Probation
reg log_Earnings i.s_SrsProbation_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
reg log_Earnings i.s_SrsProbation_L1 WorryJob_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
reg log_Earnings i.s_SrsProbation_L1 WorryJob_L1 ///
	$l1control $l2control if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)


	
	
	
	
	
* 2) AGE AT LAST OFFENSE

****
**LABOR MARKET INSECURITY
****

**Arrest
mepoisson WorryJob AgeLastArrest_L1 if sample == 1 || ParticipantID: // bivariate
mepoisson WorryJob AgeLastArrest_L1 $l1controlpmc $l2control  if sample == 1 || ParticipantID: // multivariate

**Jail
mepoisson WorryJob AgeLastJail_L1 if sample == 1 || ParticipantID: // bivariate
mepoisson WorryJob AgeLastJail_L1 $l1controlpmc $l2control  if sample == 1 || ParticipantID: // multivariate

**Probation
mepoisson WorryJob AgeLastProbation_L1 if sample == 1 || ParticipantID: // bivariate
mepoisson WorryJob AgeLastProbation_L1 $l1controlpmc $l2control  if sample == 1 || ParticipantID: // multivariate



****
**TIME OUT OF THE LABOR FORCE
****

**Arrest
mepoisson Discgd_Total AgeLastArrest_L1 if sample == 1 || ParticipantID: // bivariate
mepoisson Discgd_Total WorryJob_L1c pm_WorryJob AgeLastArrest_L1 if sample == 1 || ParticipantID: // multivariate
mepoisson Discgd_Total WorryJob_L1c pm_WorryJob AgeLastArrest_L1 $l1controlpmc $l2control  if sample == 1 || ParticipantID: // multivariate

**Jail
mepoisson Discgd_Total AgeLastJail_L1 if sample == 1 || ParticipantID: // bivariate
mepoisson Discgd_Total WorryJob_L1c pm_WorryJob AgeLastJail_L1 if sample == 1 || ParticipantID: // multivariate
mepoisson Discgd_Total WorryJob_L1c pm_WorryJob AgeLastJail_L1 $l1controlpmc $l2control  if sample == 1 || ParticipantID: // multivariate

**Probation
mepoisson Discgd_Total AgeLastProbation_L1 if sample == 1 || ParticipantID: // bivariate
mepoisson Discgd_Total WorryJob_L1c pm_WorryJob AgeLastProbation_L1 if sample == 1 || ParticipantID: // multivariate
mepoisson Discgd_Total WorryJob_L1c pm_WorryJob AgeLastProbation_L1 $l1controlpmc $l2control  if sample == 1 || ParticipantID: // multivariate



****
**TIME SEARCHING FOR WORK
****

**Arrest
mepoisson Searching_Total AgeLastArrest_L1 if sample == 1 || ParticipantID: // bivariate
mepoisson Searching_Total WorryJob_L1c pm_WorryJob AgeLastArrest_L1 if sample == 1 || ParticipantID: // multivariate
mepoisson Searching_Total WorryJob_L1c pm_WorryJob AgeLastArrest_L1 $l1controlpmc $l2control  if sample == 1 || ParticipantID: // multivariate

**Jail
mepoisson Searching_Total AgeLastJail_L1 if sample == 1 || ParticipantID: // bivariate
mepoisson Searching_Total WorryJob_L1c pm_WorryJob AgeLastJail_L1 if sample == 1 || ParticipantID: // multivariate
mepoisson Searching_Total WorryJob_L1c pm_WorryJob AgeLastJail_L1 $l1controlpmc $l2control  if sample == 1 || ParticipantID: // multivariate

**Probation
mepoisson Searching_Total AgeLastProbation_L1 if sample == 1 || ParticipantID: // bivariate
mepoisson Searching_Total WorryJob_L1c pm_WorryJob AgeLastProbation_L1 if sample == 1 || ParticipantID: // multivariate
mepoisson Searching_Total WorryJob_L1c pm_WorryJob AgeLastProbation_L1 $l1controlpmc $l2control  if sample == 1 || ParticipantID: // multivariate



****
**JOB PLACEMENT IN SECONDARY MARKET
****

*Arrest
logit Secondary AgeLastArrest_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
logit Secondary AgeLastArrest_L1 WorryJob_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
logit Secondary AgeLastArrest_L1 WorryJob_L1 ///
	$l1control $l2control if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)

*Jail
logit Secondary AgeLastJail_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
logit Secondary AgeLastJail_L1 WorryJob_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
logit Secondary AgeLastJail_L1 WorryJob_L1 ///
	$l1control $l2control if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)

*Probation
logit Secondary AgeLastProbation_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
logit Secondary AgeLastProbation_L1 WorryJob_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
logit Secondary AgeLastProbation_L1 WorryJob_L1 ///
	$l1control $l2control if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)


****
**EARNINGS
****

*Arrest
reg log_Earnings AgeLastArrest_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
reg log_Earnings AgeLastArrest_L1 WorryJob_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
reg log_Earnings AgeLastArrest_L1 WorryJob_L1 ///
	$l1control $l2control if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)

*Jail
reg log_Earnings AgeLastJail_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
reg log_Earnings AgeLastJail_L1 WorryJob_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
reg log_Earnings AgeLastJail_L1 WorryJob_L1 ///
	$l1control $l2control if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)

*Probation
reg log_Earnings AgeLastProbation_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
reg log_Earnings AgeLastProbation_L1 WorryJob_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
reg log_Earnings AgeLastProbation_L1 WorryJob_L1 ///
	$l1control $l2control if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)

log close
cls


********************************************************************************
********************************************************************************


log using "E:\[Anonymized]\Job Search\LMParticipation_PublicFiles\Log Output\SECTION 12 - Supplement - Grand Mean Centered Covariates", ///
	text replace
***************************************************
*SUPPLEMENTAL ESTIMATES: GRAND MEAN CENTERED VALUES
***************************************************
*	Estimates mirror those in text with grand mean centered values replaced for
*	person mean centered values.
	
*Macros for Models
global state Employed_Total Searching_Total Discgd_Total
global contact ArrestEver_L1 JailEver_L1 ProbationEver_L1
global l1control i.GraduatedHS_L1 EnrollNow_L1 Relationship_L1 Kids_L1 ///
	UnemploymentComp_L1 Health_L1 AlcUse_L1 FINScale_L1 DISScale_L1 Crash_L1 ///
	ForceOut_L1 Risky_L1 AGE_L1
global l1controlgmc i.GraduatedHS_L1 EnrollNow_L1 Relationship_L1 Kids_L1 ///
	UnemploymentComp_L1 Health_L1gmc AlcUse_L1 FINScale_L1gmc DISScale_L1gmc Crash_L1 ///
	ForceOut_L1 Risky_L1gmc AGE_L1gmc
global l2control Sex i.Race	
	
****
**LABOR MARKET INSECURITY
****

**Arrest
mepoisson WorryJob ArrestEver_L1 $l1controlgmc $l2control  if sample == 1 || ParticipantID: // multivariate

**Jail
mepoisson WorryJob JailEver_L1 $l1controlgmc $l2control  if sample == 1 || ParticipantID: // multivariate

**Probation
mepoisson WorryJob ProbationEver_L1 if sample == 1 || ParticipantID: // bivariate
mepoisson WorryJob ProbationEver_L1 $l1controlgmc $l2control  if sample == 1 || ParticipantID: // multivariate



****
**TIME OUT OF THE LABOR FORCE
****

**Arrest
mepoisson Discgd_Total WorryJob_L1gmc if sample == 1 || ParticipantID: // bivariate
mepoisson Discgd_Total WorryJob_L1gmc ArrestEver_L1 if sample == 1 || ParticipantID: // multivariate
mepoisson Discgd_Total WorryJob_L1gmc ArrestEver_L1 $l1controlgmc $l2control  if sample == 1 || ParticipantID: // multivariate

**Jail
mepoisson Discgd_Total WorryJob_L1gmc if sample == 1 || ParticipantID: // bivariate
mepoisson Discgd_Total WorryJob_L1gmc JailEver_L1 if sample == 1 || ParticipantID: // multivariate
mepoisson Discgd_Total WorryJob_L1gmc JailEver_L1 $l1controlgmc $l2control  if sample == 1 || ParticipantID: // multivariate

**Probation
mepoisson Discgd_Total WorryJob_L1gmc if sample == 1 || ParticipantID: // bivariate
mepoisson Discgd_Total WorryJob_L1gmc ProbationEver_L1 if sample == 1 || ParticipantID: // multivariate
mepoisson Discgd_Total WorryJob_L1gmc ProbationEver_L1 $l1controlgmc $l2control  if sample == 1 || ParticipantID: // multivariate



****
**TIME SEARCHING FOR WORK
****

**Arrest
mepoisson Searching_Total WorryJob_L1gmc if sample == 1 || ParticipantID: // bivariate
mepoisson Searching_Total WorryJob_L1gmc ArrestEver_L1 if sample == 1 || ParticipantID: // multivariate
mepoisson Searching_Total WorryJob_L1gmc ArrestEver_L1 $l1controlgmc $l2control  if sample == 1 || ParticipantID: // multivariate

**Jail
mepoisson Searching_Total WorryJob_L1gmc if sample == 1 || ParticipantID: // bivariate
mepoisson Searching_Total WorryJob_L1gmc JailEver_L1 if sample == 1 || ParticipantID: // multivariate
mepoisson Searching_Total WorryJob_L1gmc JailEver_L1 $l1controlgmc $l2control  if sample == 1 || ParticipantID: // multivariate

**Probation
mepoisson Searching_Total WorryJob_L1gmc if sample == 1 || ParticipantID: // bivariate
mepoisson Searching_Total WorryJob_L1gmc ProbationEver_L1 if sample == 1 || ParticipantID: // multivariate
mepoisson Searching_Total WorryJob_L1gmc ProbationEver_L1 $l1controlgmc $l2control  if sample == 1 || ParticipantID: // multivariate	
	
log close
cls



********************************************************************************
********************************************************************************


log using "E:\[Anonymized]\Job Search\LMParticipation_PublicFiles\Log Output\SECTION 13 - Supplement - Job Quality wo Market State Vars", ///
	text replace
****************************************************************************
*SUPPLEMENTAL ESTIMATES: JOB QUALITY ESTIMATES WITHOUT TIME IN MARKET STATES
****************************************************************************

*Macros for Models
global state Employed_Total Searching_Total Discgd_Total
global contact ArrestEver_L1 JailEver_L1 ProbationEver_L1
global l1control i.GraduatedHS_L1 EnrollNow_L1 Relationship_L1 Kids_L1 ///
	UnemploymentComp_L1 Health_L1 AlcUse_L1 FINScale_L1 DISScale_L1 Crash_L1 ///
	ForceOut_L1 Risky_L1 AGE_L1
global l2control Sex i.Race

****
**JOB PLACEMENT IN SECONDARY MARKET
****

*Arrest
logit Secondary ArrestEver_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID) or
logit Secondary WorryJob_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID) or
logit Secondary ArrestEver_L1 WorryJob_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID) or
logit Secondary ArrestEver_L1 WorryJob_L1 $l1control $l2control ///
	if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID) or

*Jail
logit Secondary JailEver_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID) or
logit Secondary WorryJob_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID) or
logit Secondary JailEver_L1 WorryJob_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID) or
logit Secondary JailEver_L1 WorryJob_L1 $l1control $l2control ///
	if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID) or

*Probation
logit Secondary ProbationEver_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID) or
logit Secondary WorryJob_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID) or
logit Secondary ProbationEver_L1 WorryJob_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID) or
logit Secondary ProbationEver_L1 WorryJob_L1 $l1control $l2control ///
	if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID) or


****
**EARNINGS
****

*Arrest
reg log_Earnings ArrestEver_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
reg log_Earnings WorryJob_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
reg log_Earnings ArrestEver_L1 WorryJob_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
reg log_Earnings ArrestEver_L1 WorryJob_L1 $l1control $l2control ///
	if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)

*Jail
reg log_Earnings JailEver_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
reg log_Earnings WorryJob_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
reg log_Earnings JailEver_L1 WorryJob_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
reg log_Earnings JailEver_L1 WorryJob_L1 $l1control $l2control ///
	if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)

*Probation
reg log_Earnings ProbationEver_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
reg log_Earnings WorryJob_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
reg log_Earnings ProbationEver_L1 WorryJob_L1 if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)
reg log_Earnings ProbationEver_L1 WorryJob_L1 $l1control $l2control ///
	if TransitionEmploy == 1 & sample == 1, cluster(ParticipantID)

log close
cls












