{smcl}
{* *! * version 1.2  AH 18 Apr 2021 }{...}
{viewerdialog splittvc "dialog splittvc"}{...}
{viewerjumpto "Syntax" "splittvc##syntax"}{...}
{viewerjumpto "Description" "splittvc##description"}{...}
{viewerjumpto "Options" "splittvc##options"}{...}
{viewerjumpto "Examples" "splittvc##examples"}{...}
{p2colset 1 20 20 2}{...}
{p2col:{bf:[S] splittvc} {hline 2}} Split records to creates time-varying covariates {p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 18 2}
{cmdab:splittvc} id start end eventtime event
[{cmd:,}
{it:options}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}

{syntab:Options}
{synopt:{opt listid(string)}}list ids specified in string {p_end}
{synopt:{opt nolab:el}}suppress value label in list {p_end}
{synopt:{opt tvcmi:ssing}}lists events occurring in event but not in time-varying event {p_end}

{marker description}{...}
{title:Description}

{pstd}
{opt splittvc} splits person time at specified event dates and generates a time-varying covariate. The command requires five variables: 
- id: unique identifier (numeric or string) 
- start: date of follow-up time of record (numeric)
- end: end of follow-up time of record (numeric)
- event: binary indicator for event (numeric)
- eventtime: event time (numeric)
Multiple rows per id are permitted. The dataset should not include observations without person-time at risk (_st==0). 


{marker examples}{...}
{title:Examples}

Dataset before splitting 
   +-----------------------------------------------------------+
   | patient         start           end    eventtime   event  |
   |-----------------------------------------------------------|
   |     131   01 Jan 2011   01 Jul 2020           .     0     | 
   |-----------------------------------------------------------|
   |    5631   01 Jan 2011   01 Jul 2020   30 Nov 15     1     |
   +-----------------------------------------------------------+

{phang}{cmd:. splittvc patient start end eventtime event, listid(131, 5631) nolab tvcmissing }{p_end}

Dataset after splitting
   +---------------------------------------------------------------------+
   | patient         start           end    eventtime  event   event_tvc |
   |---------------------------------------------------------------------|
   |     131   01 Jan 2011   01 Jul 2020           .     0         0     |
   |---------------------------------------------------------------------|
   |    5631   01 Jan 2011   30 Nov 2015   30 Nov 15     1         0     |
   |    5631   30 Nov 2015   01 Jul 2020   30 Nov 15     1         1     |
   +---------------------------------------------------------------------+

Use quotation marks in the option listid() if id is a string variable.  
{phang}{cmd:. splittvc patient start end eventtime event, listid("131", "5631")}{p_end}
		 
{marker author}{...}
{title:Author}
{pstd}
Andreas Haas, Email: andreas.haas@ispm.unibe.ch
