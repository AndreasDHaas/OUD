# computing excess life-years lost due to mental disorders in Bonitas, using lillies package
# point estimates only

library(data.table)
library(tictoc)
library(survival)
library(lillies)
library(readstata13)

tic("overall")

filepath_read <- "C:/ISPM/Data/HIV-mental disorders/opioid use"
filepath_read_cod <- "C:/ISPM/Data/AfA-Bonitas/Stata/Bonitas_20211020"
source(file="C:/ISPM/HomeDir/HIV-mental disorders/OUD/R Code/timeSplit_DT.R")
save_filename <- "C:/ISPM/Data/HIV-mental disorders/lillies/estimates_opioid/elyl.RData"

#which_mhd <- c("oud","dep","smi","anx","mhd")
which_mhd <- "oud"
which_sex <- c("both","men","women")

min_age <- 11
max_age <- 85

tic("loading data")
data_surv <- suppressWarnings(data.table(read.dta13(file.path(filepath_read,"lyl.dta"))))   # dataset provided by Andreas
tblVITAL <- suppressWarnings(data.table(read.dta13(file.path(filepath_read_cod,"VITAL.dta"))))
data_surv[,`:=`(start=NULL,end=NULL)]
toc()

# recoding patient ids
data_surv[,patient:=vapply(patient,FUN=function(old_code) paste0("B",paste0(rep("0",9-nchar(old_code)),collapse=""),as.character(old_code)),FUN.VALUE="")]

# appending cause of death & excluding patients with unknown cause of death
data_surv <- merge(data_surv,tblVITAL[,.(patient,cod=cod2)],by="patient",all.x=TRUE)
data_surv <- data_surv[cod!=4 | is.na(cod)]
data_surv[,cod:=as.character(cod)]
data_surv[cod=="1",cod:="Natural"]
data_surv[cod=="2",cod:="Unnatural"]

# counting process format, one line per patient, on 'age' scale
data_surv[,`:=`(start=as.numeric(baseline_d-birth_d)/365.25,
                stop=as.numeric(end_d-birth_d)/365.25,
                status=as.numeric(death_y=="Died"))]

data_surv[status==1 & death_d>end_d,status:=0]    # censoring deaths occurring after patient leaves Bonitas
data_surv <- data_surv[start<stop]                # removing patients with no follow-up

# left-truncataion/right-censoring (age)
data_surv <- data.table(survSplit(Surv(start,stop,status)~.,data=data_surv,cut=c(min_age,max_age),episode="i"))
data_surv <- data_surv[i==2]
data_surv[,i:=NULL]

# cleaning up cause of death
data_surv[status==0,cod:="Alive"]
data_surv[,cod:=factor(cod,levels=c("Alive","Natural","Unnatural"))]

# looping over types of mental disorders and sex
LYL_diff_df <- data.frame(NULL)
for(ggg in which_sex)
{
  for(v in which_mhd)
  {
    tic(paste(ggg,v))
    DT <- copy(data_surv)
    
    if(ggg=="men")
      DT <- DT[sex=="Male"]
    if(ggg=="women")
      DT <- DT[sex=="Female"]
    
    setnames(DT,paste0(v,"_sd"),"treat_sd")
    
    # age at mhd treatment
    DT[,age_treat:=as.numeric(treat_sd-birth_d)/365.25]
    DT[age_treat>=stop,age_treat:=NA] # excluding disorders occurring post-censoring
    DT[!is.na(age_treat) & age_treat<start,age_treat:=start]   # carrying forward prevalent disorders
    age_treat <- DT[!is.na(age_treat),age_treat]
    
    # splitting time-at-risk into exposed/unexposed
    DT_exp <- DT[!is.na(age_treat)]
    DT_unexp <- timeSplit_DT(X=DT,vars_date="age_treat",vars_tu="cens",event="status",start_date="start",stop_date="stop",id_var="patient",print_out=FALSE)
    DT_unexp <- DT_unexp[cens==0]
    DT_unexp[,cens:=NULL]
    DT_unexp[status==0,cod:="Alive"]
    
    # computing excess LYL, exposed vs. unexposed
    LYL_exp <- lyl_range(data=DT_exp,t0=age_treat,t=stop,status=cod,age_begin=min_age,age_end=max_age-1,tau=max_age)
    LYL_unexp <- lyl_range(data=DT_unexp,t0=start,t=stop,status=cod,age_begin=min_age,age_end=max_age-1,tau=max_age)
    LYL_diff <- lyl_diff(LYL_exp,LYL_unexp,weights=age_treat)
    
    
    LYL_diff_df <- rbind(LYL_diff_df,data.frame("type"=v,"sex"=ggg,LYL_diff,"nb_patients"=DT[,.N],"nb_exposed"=length(age_treat),
                                                "nb_nat_deaths"=DT[,sum(cod=="Natural")],"nb_unnat_deaths"=DT[,sum(cod=="Unnatural")],
                                                "nb_deaths"=DT[,sum(cod!="Alive")],"py"=DT[,sum(stop-start)]))
    
    rm(DT_exp,DT_unexp,DT,age_treat)
    toc()
  }
}

LYL_diff_df <- data.table(LYL_diff_df)
LYL_diff_df[,life_exp:=NULL]
setnames(LYL_diff_df,"TotalLYL","Excess LYL")
save(LYL_diff_df,file=save_filename)

toc()
