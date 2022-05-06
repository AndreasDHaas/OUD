# processing/diagnosis of bootstrap samples

library(data.table)
library(ggplot2)

filepath_read <- "C:/ISPM/Data/HIV-mental disorders/lillies/estimates_opioid"

which_mhd <- "oud"
which_sex <- "women"
max_age <- 85
nb_chunks <- 20

df_full <- data.table(NULL)

for(i in 1:nb_chunks)
{
  chunk <- data.table(read.table(file.path(filepath_read,paste0("ELYL_",which_mhd,"_",which_sex,"_",max_age,"_","boot_c",i,".RData"))))
  df_full <- rbind(df_full,chunk)
  rm(chunk)
}

df_full[,tp:=1:df_full[,.N]]
for(j in 1:df_full[,.N])
{
  df_full[j,`:=`(TotalLYL_mean=mean(df_full[1:j,TotalLYL]),TotalLYL_lower=quantile(df_full[1:j,TotalLYL],p=0.025),TotalLYL_upper=quantile(df_full[1:j,TotalLYL],p=0.975),
           Natural_mean=mean(df_full[1:j,Natural]),Natural_lower=quantile(df_full[1:j,Natural],p=0.025),Natural_upper=quantile(df_full[1:j,Natural],p=0.975),
           Unnatural_mean=mean(df_full[1:j,Unnatural]),Unnatural_lower=quantile(df_full[1:j,Unnatural],p=0.025),Unnatural_upper=quantile(df_full[1:j,Unnatural],p=0.975))]
}

print(round(df_full[.N,.(TotalLYL_lower,TotalLYL_upper,Natural_lower,Natural_upper,Unnatural_lower,Unnatural_upper)],digits=2))

pp_Total <- ggplot(aes(x=tp,y=TotalLYL_mean),data=df_full) +
  geom_line(size=0.5) +
  geom_ribbon(aes(ymin=TotalLYL_lower,ymax=TotalLYL_upper),linetype=2,alpha=0.3)

pp_Natural <- ggplot(aes(x=tp,y=Natural_mean),data=df_full) +
  geom_line(size=0.5) +
  geom_ribbon(aes(ymin=Natural_lower,ymax=Natural_upper),linetype=2,alpha=0.3)

pp_Unnatural <- ggplot(aes(x=tp,y=Unnatural_mean),data=df_full) +
  geom_line(size=0.5) +
  geom_ribbon(aes(ymin=Unnatural_lower,ymax=Unnatural_upper),linetype=2,alpha=0.3)

df_full[,hist(Natural)]
df_full[,hist(Unnatural)]
df_full[,hist(TotalLYL)]