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

	TD=j(&x_end.-&x_radix.+1,9,0);
	
	do i=&x_radix. to &x_end. by 1;
		TD[i-&x_radix.+1,1]=i;
		TD[i-&x_radix.+1,2]=i-2;
		if i=&x_radix. then
			TD[i-&x_radix.+1,3]=&l_radix.;
		else
		do;
			/*l_x+2*/
			TD[i-&x_radix.+1,3]=&l_radix.*exp(-&A.*(TD[i-&x_radix.+1,1]-TD[1,1])-&B./log(&c.)*&c.**TD[1,1]*(&c.**(TD[i-&x_radix.+1,1]-TD[1,1])-1));
			/*l_[x]*/
			TD[i-&x_radix.+1,4]=TD[i-&x_radix.+1,3]/exp((1-&c2.**2)/log(&c2.)*&A.+(&c.**2-&c2.**2)/log(&c2./&c.)*&B.*&c.**TD[i-&x_radix.+1,2]);
			/*l_{[x]+1}*/
			TD[i-&x_radix.+1,5]=TD[i-&x_radix.+1,4]*exp(&c2.*(1-&c2.)/log(&c2.)*&A.+(&c.-&c2.)/log(&c2./&c.)*&B.*&c.**TD[i-&x_radix.+1,2]);
		end;
	end;
	
	do i=&x_radix. to &x_end. by 1;
		/*q_{x+2}*/		
		if i=&x_end. then 
			do;		
				TD[i-&x_radix.+1,6]=1;
			end;
		else
			TD[i-&x_radix.+1,6]=(TD[i-&x_radix.+1,3]-TD[i-&x_radix.+2,3])/TD[i-&x_radix.+1,3];
			
	end;

	do i=&x_end. to &x_radix. by -1;
				
		if i=&x_end. then 
			do;		
				TD[i-&x_radix.+1,7]=1;
				/* aa_{[x]+1} */
				TD[i-&x_radix.+1,8]=1+1/(1+&i.)*TD[i-&x_radix.+1,3]/TD[i-&x_radix.+1,5]*TD[i-&x_radix.+1,7];
				/* aa_{[x]} */
				TD[i-&x_radix.+1,9]=1+1/(1+&i.)*TD[i-&x_radix.+1,5]/TD[i-&x_radix.+1,4]*TD[i-&x_radix.+1,8];			
			end;
		else
			do;
				/*aa_{x+2}*/
				TD[i-&x_radix.+1,7]=1+1/(1+&i.)*(1-TD[i-&x_radix.+1,6])*TD[i-&x_radix.+2,7];
				/* aa_{[x]+1} */
				TD[i-&x_radix.+1,8]=1+1/(1+&i.)*TD[i-&x_radix.+1,3]/TD[i-&x_radix.+1,5]*TD[i-&x_radix.+1,7];
				/* aa_{[x]} */
				TD[i-&x_radix.+1,9]=1+1/(1+&i.)*TD[i-&x_radix.+1,5]/TD[i-&x_radix.+1,4]*TD[i-&x_radix.+1,8];
			end;
	end;



	print TD;
	
	
run;







