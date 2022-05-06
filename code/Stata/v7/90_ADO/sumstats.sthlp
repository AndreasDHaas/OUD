{smcl}
{* *! * version 1.2  AH 16 Aug 2021 }{...}
{viewerdialog sumstats "dialog sumstats"}{...}
{viewerjumpto "Syntax" "sumstats##syntax"}{...}
{viewerjumpto "Description" "sumstats##description"}{...}
{viewerjumpto "Options" "sumstats##options"}{...}
{viewerjumpto "Examples" "sumstats##examples"}{...}
{p2colset 1 20 20 2}{...}
{p2col:{bf:[T] sumstats} {hline 2}} Calculate summary statistics {p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 18 2}
{cmdab:sumstats} {varname} stratavar 
{ifin}
[{cmd:,}
{it:options}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}

{syntab:Main}
{synopt:{opt append(string)}}append output to table specified in string{p_end}
{synopt:{opt mean}}report mean and SD (default){p_end}
{synopt:{opt ext:reme}}report min and max{p_end}
{synopt:{opt median}}report median and IQR{p_end}
{synopt:{opt ttest}}report p-value from t-test{p_end}
{synopt:{opt wilc:oxon}}report p-value from Wilcoxon test{p_end}
{synopt:{opt lab:el(string)}}label estimates with string{p_end}
{synopt:{opt head:ing(string)}}add row with heading specified in string{p_end}
{synopt:{opt clean(string)}}show clean version of table in output{p_end}

{syntab:Format}
{synopt:{opt format(string)}}format numbers according to Stata format specified in string{p_end}
{synopt:{opt labelf:ormat(string)}}format label column according to Stata format specified in string{p_end}
{synopt:{opt pf:ormat(string)}}format p-values according to Stata format specified in string{p_end}
{synopt:{opt ind:ent(integer)}}indent estimate label by the number of blanks specified, (default=2){p_end}
{synopt:{opt brackets}}replace parentheses with brackets{p_end}
{synopt:{opt midpoint}}use midpoint as decimal point separator{p_end}
{synopt:{opt nomis:sings}}replaces . for missings with blank {p_end}

{syntab:Advanced}
{synopt:{opt varsu:ffix(string)}}rename all variables in table with suffix{p_end}

{marker description}{...}
{title:Description}

{pstd}
{opt sumstats} calculates summary statistics of varname stratified by stratavar and appends the formatted table to an existing table created with the user-written commands header.ado, colprc.ado or sumstats.ado. 

{marker examples}{...}
{title:Examples}

    Setup	
{phang}{cmd:. sysuse auto}{p_end}
{phang}{cmd:. recode price (min/4999 =1 "<5,000") (5000/9999 =2 "5,000-9,999") (10000/max =3 "10,000+"), gen(price_cat)}{p_end}

    Generate table header 
{phang}{cmd:. header foreign, saving("Table 1") percentformat(%3.1fc) freqlab("N=") clean freqf(%9.0fc) percentsign pvalue}{p_end}

    Append rows with frequencies and column percentages for variable price_cat to table header
{phang}{cmd:. colprc price_cat foreign, append("Table 1") percentformat(%3.1fc) freqf(%5.0fc) heading("Price, USD") clean chi percentsign} {p_end}

    Append rows with median and IQR table 
{phang}{cmd:. sumstats price foreign, append("Table 1") format(%5.0fc) median clean ttest} {p_end}

    Load table in memory and prepare for export in word
{phang}{cmd:. tblout using "Table 1", clear merge align format("%15s")} {p_end}

    Export table in word
{phang}{cmd:. capture putdocx clear} {p_end}
{phang}{cmd:. putdocx begin, font("Arial", 8)} {p_end}
{phang}{cmd:. putdocx paragraph, spacing(after, 0)} {p_end}
{phang}{cmd:. putdocx text ("Table 1: Characteristics of cars by foreign"), font("Arial", 9, black) bold}{p_end}
{phang}{cmd:. putdocx table tbl1 = data(*), border(all, nil) border(top, single) border(bottom, single) layout(autofitcontent)}{p_end}
{phang}{cmd:. putdocx table tbl1(., .), halign(right)  font("Arial", 8)}{p_end}
{phang}{cmd:. putdocx table tbl1(., 1), halign(left)}{p_end}
{phang}{cmd:. putdocx table tbl1(1, .), halign(center) bold}{p_end}
{phang}{cmd:. putdocx table tbl1(2, .), halign(center)  border(bottom, single)} {p_end}
{phang}{cmd:. putdocx save "Table 1.docx", replace} {p_end}
		 
{marker author}{...}
{title:Author}
{pstd}
Andreas Haas, Email: andreas.haas@ispm.unibe.ch
