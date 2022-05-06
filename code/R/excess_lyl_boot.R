# create series of bootstrap excess LYL estimates, for a specific pre-set of parameters (MHD type, sex, max age)
# for job array submission over HPC servers, cannot be run locally
# using list of pre-sets written in an Excel file ('lookup_elyl.xslx')

library(data.table)
library(tictoc)
library(survival)
library(lillies)
library(scriptName)
library(writexl)
library(readstata13)

filepath_read <- "~/MHD/R/input/Bonitas"
filepath_write <- "~/MHD/R/output/lyl"
filepath_lookup <- "~/MHD/R/lookup"
source("~/MHD/R/Code/Utils/timeSplit_DT.R")

min_age <- 11

tic("overall")

tic("data imported")
mhd_lookup <- readxl::read_xlsx(path=file.path(filepath_lookup,"lookup_elyl.xlsx"))
x <- unlist(strsplit(current_filename(),"/"))
id_num <- as.numeric(gsub("[^\\d]+", "",x[length(x)], perl=TRUE))
which_mhd <- mhd_lookup$exposure[mhd_lookup$id==id_num]
which_sex <- mhd_lookup$sex[mhd_lookup$id==id_num]
max_age <- mhd_lookup$max_age[mhd_lookup$id==id_num]
stopifnot(which_sex%in%c("both","men","women"))
chunk <- mhd_lookup$chunk[mhd_lookup$id==id_num]
nb_boot <- mhd_lookup$nb_boot[mhd_lookup$id==id_num]
rm(x,id_num)

set.seed(chunk*16)

data_surv <- suppressWarnings(data.table(read.dta13(file.path(filepath_read,"lyl.dta"))))
tblVITAL <- suppressWarnings(data.table(read.dta13(file.path(filepath_read,"VITAL.dta"))))

save_filename <- paste0("ELYL_",which_mhd,"_",which_sex,"_",max_age,"_boot_c",chunk,".RData")
toc()

print(save_filename)

if(which_sex=="men")
  data_surv <- data_surv[sex=="Male"]
if(which_sex=="women")
  data_surv <- data_surv[sex=="Female"]

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

# looping over types of mental disorders
LYL_diff_df <- data.frame(NULL)
setnames(data_surv,paste0(which_mhd,"_sd"),"treat_sd")

# age at mhd treatment
data_surv[,`:=`(age_treat=as.numeric(treat_sd-birth_d)/365.25)]
data_surv[!is.na(age_treat) & age_treat<start,age_treat:=start]
data_surv[age_treat>=stop,age_treat:=NA] # excluding disorders occuring post-censoring

LYL_diff_boot <- NULL
no_deaths_vect <- NULL

for(i in 1:nb_boot)
{
  print(i)
  DT_boot <- data_surv[sample(1:.N,replace=TRUE)]    # bootstrap re-sampling
  DT_exp <- DT_boot[!is.na(age_treat)]
  DT_unexp <- timeSplit_DT(X=DT_boot,vars_date="age_treat",vars_tu="cens",event="status",start_date="start",stop_date="stop",id_var="patient",print_out=FALSE)
  DT_unexp <- DT_unexp[cens==0]
  DT_unexp[,cens:=NULL]
  DT_unexp[status==0,cod:="Alive"]
  
  if(DT_exp[,any(cod!="Alive")])   # checking that there is at least one death among the exposed, otherwise ELYL must be determined manually
  {
    suppressMessages(LYL_exp <- lyl_range(data=DT_exp,t0=age_treat,t=stop,status=cod,age_begin=min_age,age_end=max_age-1,tau=max_age))
    suppressMessages(LYL_unexp <- lyl_range(data=DT_unexp,t0=start,t=stop,status=cod,age_begin=min_age,age_end=max_age-1,tau=max_age))
    LYL_diff <- lyl_diff(LYL_exp,LYL_unexp,weights=DT_exp[,age_treat])
    LYL_diff_boot <- rbind(LYL_diff_boot,data.frame(LYL_diff))
    
  } else        # in case of no deaths in exposed, LYL is zero in that population
  {
    no_deaths_vect <- c(no_deaths_vect,i)
    W <- DT_exp[,floor(age_treat)]
    suppressMessages(LYL_unexp <- lyl_range(data=DT_unexp,t0=start,t=stop,status=cod,age_begin=min_age,age_end=max_age-1,tau=max_age))
    LYL <- LYL_unexp$LYL
    ind <- match(W,LYL$age)
    lyl_nd <- -mean(LYL$natural[ind])
    lyl_ud <- -mean(LYL$unnatural[ind])
    LYL_diff_boot <- rbind(LYL_diff_boot,data.frame(life_exp=-(lyl_nd+lyl_ud),TotalLYL=lyl_nd+lyl_ud,natural=lyl_nd,unnatural=lyl_ud))
    rm(W,LYL,ind,lyl_nd,lyl_ud)
  }
  rm(DT_exp,DT_unexp,DT_boot)
}

print("iterations with no deaths in exposed:")
print(no_deaths_vect)
write.table(LYL_diff_boot,file=file.path(filepath_write,save_filename))


toc()