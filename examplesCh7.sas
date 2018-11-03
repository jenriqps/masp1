/**********************************************************************
 * Notas de Clase de Matematicas Actuariales del Seguro de Personas I ;
 * Jose Enrique Perez ;
 * Facultad de Ciencias. Universidad Nacional Autónoma de México ;
 **********************************************************************/
options mprint mlogic minoperator fullstimer;
ods graphics / reset width=6.4in height=4.8in imagemap noborder;

%let origen=/folders/myfolders/masp1;
%include "&origen./configuration.sas";
%include "&origen./extInputs.sas";
%include "&origen./macros.sas";

proc datasets lib=work kill nolist;
run;

%examplesChapter7(example=&example_.,i=&i_.,x=&x_.,bft=&bft_.,fxExp=&fxExp_.,pcExp=&pcExp_.,fxInitExp=&fxInitExp.,fxFinExp=&fxFinExp.,G=&G.,n=&n.,unitBft=&unitBft.,fxExpXunitBft=&fxExpXunitBft.,fxExpXunitG=&fxExpXunitG.,pcInitExp=&pcInitExp.)
;

* Parámetros de la tabla Dickson;
%let A =	0.00022;
%let B =	0.0000027;
%let c =	1.124;
%let c2=0.9;
%let l_radix=100000;
%let x_radix=20;
%let x_end=131;
%let i=0.05;

proc iml;

	SLT=j(&x_end.-&x_radix.+1,9,0);
	
	do x=&x_radix. to &x_end. by 1;
		SLT[x-&x_radix.+1,1]=x;
		SLT[x-&x_radix.+1,2]=x-2;
		if x=&x_radix. then
			SLT[x-&x_radix.+1,3]=&l_radix.;
		else
		do;
			/*l_x+2*/
			SLT[x-&x_radix.+1,3]=&l_radix.*exp(-&A.*(SLT[x-&x_radix.+1,1]-SLT[1,1])-&B./log(&c.)*&c.**SLT[1,1]*(&c.**(SLT[x-&x_radix.+1,1]-SLT[1,1])-1));
			if x >= &x_radix.+2 then
				do;
					/*l_[x]*/
					SLT[x-&x_radix.+1,4]=SLT[x-&x_radix.+1,3]/exp((1-&c2.**2)/log(&c2.)*&A.+(&c.**2-&c2.**2)/log(&c2./&c.)*&B.*&c.**SLT[x-&x_radix.+1,2]);
					/*l_{[x]+1}*/
					SLT[x-&x_radix.+1,5]=SLT[x-&x_radix.+1,4]*exp(&c2.*((1-&c2.)/log(&c2.)*&A.+(&c.-&c2.)/log(&c2./&c.)*&B.*&c.**SLT[x-&x_radix.+1,2]));
				end;
		end;
	end;
	
	do x=&x_radix. to &x_end. by 1;
		/*q_{x+2}*/		
		if x=&x_end. then 
			do;		
				SLT[x-&x_radix.+1,6]=1;
			end;
		else
			SLT[x-&x_radix.+1,6]=(SLT[x-&x_radix.+1,3]-SLT[x-&x_radix.+2,3])/SLT[x-&x_radix.+1,3];
			
	end;

	do x=&x_end. to &x_radix. by -1;
				
		if x=&x_end. then 
			do;		
				SLT[x-&x_radix.+1,7]=1;
				/* aa_{[x]+1} */
				SLT[x-&x_radix.+1,8]=1+1/(1+&i.)*SLT[x-&x_radix.+1,3]/SLT[x-&x_radix.+1,5]*SLT[x-&x_radix.+1,7];
				/* aa_{[x]} */
				SLT[x-&x_radix.+1,9]=1+1/(1+&i.)*SLT[x-&x_radix.+1,5]/SLT[x-&x_radix.+1,4]*SLT[x-&x_radix.+1,8];			
			end;
		else
			do;
				/*aa_{x+2}*/
				SLT[x-&x_radix.+1,7]=1+1/(1+&i.)*(1-SLT[x-&x_radix.+1,6])*SLT[x-&x_radix.+2,7];
				if x >= &x_radix.+2 then
					do;
						if x >= &x_radix.+2 then
							do;
								/* aa_{[x]+1} */
								SLT[x-&x_radix.+1,8]=1+1/(1+&i.)*SLT[x-&x_radix.+1,3]/SLT[x-&x_radix.+1,5]*SLT[x-&x_radix.+1,7];
								/* aa_{[x]} */
								SLT[x-&x_radix.+1,9]=1+1/(1+&i.)*SLT[x-&x_radix.+1,5]/SLT[x-&x_radix.+1,4]*SLT[x-&x_radix.+1,8];
							end;
					end;
			end;
	end;

	create trsf.SLT from SLT[colname={"x_p_2", "x", "l_x_p_2", "l_x", "l_x_p_1", 
			"q_x_p_2", "aa_x_p_2", "aa_x_p_1","aa_x"}];
		append from SLT;
		close trsf.SLT;	
	
run;

data trsf.SLT;
	format 
	x_p_2 x 3. 
	l_x l_x_p_1 l_x_p_2 comma32.2 
	q_x_p_2 aa_x aa_x_p_1 aa_x_p_2 comma32.6;
	label 
	x_p_2="x+2"
	x="x"
	l_x_p_2="l_x+2"
	l_x="l_[x]"
	l_x_p_1="l_[x]+1"
	q_x_p_2="q_x+2"
	aa_x_p_2="ä_x+2"
	aa_x_p_1="ä_[x]+1"
	aa_x="ä_[x]"
	;
	set trsf.SLT;
run;


proc print data=trsf.SLT label noobs;
run;








