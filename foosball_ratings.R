library(tidyverse)
library(brms)
library(tidybayes)
library(modelr)
library(extrafont)

#import data
df <- read.csv('foosball.csv') %>% 
  mutate(game.id = row_number())

#get preliminary player stats
player_stats <- pivot_longer(df,names_to='position',values_to = 'player',c("red_1","red_2","yellow_1","yellow_2")) %>% 
  separate(position, into = c("team","position")) %>% 
  mutate(win=if_else(team=="red",diff>0,diff<0),score=if_else(team=="red",diff,-diff)) %>% 
  group_by(player) %>% 
  summarise(games = n(), wins=sum(win), winrate = wins/games,points_avg=mean(score))

#make a dataframe that will dummy-encode the presence or absence of players for each match
player_data <- pivot_longer(df,names_to='position',values_to = 'player',c("red_1","red_2","yellow_1","yellow_2")) %>% 
  separate(position, into = c("team","position")) %>%
  mutate(team_contrast = if_else(team=='red',1,-1)) %>% 
  # mutate(
  #   team_contrast = team_contrast * sign(diff),
  #   diff = if_else(diff<0,abs(diff),diff)) %>% 
  select(player,team_contrast,game.id, diff) %>% 
  pivot_wider(names_from = player, values_from=team_contrast,id_cols=c(game.id,diff),values_fn = list) %>% 
  unnest(where(is.list),keep_empty = T) %>% 
  mutate_all(~replace(., is.na(.), 0))

player_names <- player_data %>% 
  select(-game.id,-diff) %>% 
  colnames

# Create formula
response_variable <- 'diff'
formula_string <- paste(response_variable, "~", paste(player_names, collapse = " + "))

# Convert to formula
formula <- as.formula(formula_string)

#run a model that will predict goal differential based on the combination of players(?)
m1 <- player_data %>% 
  brm(
    formula,
    data=.,
    chains=4,iter=2000,cores=4,
    prior=c(
      prior(student_t(3,0,1), class="Intercept"),
      prior(student_t(3,0,1), class="b"),
      prior(exponential(1), class="sigma")
    ),
    backend='cmdstanr'
  )

m2 <- player_data %>% 
  brm(
    formula,
    data=.,
    chains=4,iter=2000,cores=4,
    prior=c(
      prior(student_t(3,0,1), class="Intercept"),
      prior(normal(0,5), class="b"),
      prior(exponential(1), class="sigma")
    ),
    backend='cmdstanr'
  )

#get posterior predictions with the Intercept

post_pred <- as_tibble(diag(length(player_names)))
colnames(post_pred) <- player_names
post_pred <- post_pred %>% mutate(names=player_names)

post_pred %>% 
  add_epred_draws(m1) %>%
  mutate(names = str_to_title(names)) %>% 
  ggplot(aes(
    x=.epred,
    y=names,
    fill=names
  )) +
  stat_halfeye()+
  theme_bw()+
  xlab("Expected score")+
  ggtitle("Score when player is on the Red Team") +
  theme(text=element_text(size=20,family="Roboto"))

#pure player coefficients (probably more useful?)
p2 <- gather_draws(m2,`b_[a-zš]+`,regex=T) %>% 
  separate_wider_delim(.variable,'_',names = c("b","name")) %>% 
  filter(name %in% (player_stats %>% filter(games>=10) %>% .$player)) %>% 
  mutate(name = str_to_title(name)) %>% 
  ggplot(aes(
    x=.value,
    y=reorder(name,.value),
    fill=name
  )) +
  stat_halfeye()+
  theme_bw()+
  xlab("Expected goal differential")+
  ylab("Player")+
  ggtitle("Estimated effect of player") +
  theme(text=element_text(size=20,family="Roboto")) +
  scale_fill_discrete(direction=-1)+
  geom_vline(xintercept=0,linetype=2) +
  guides(fill="none")

#use postpred to create a a hypothetical match and get posterior predictions:
post_pred %>% 
  select(-names) %>%
  head(1) %>% 
  mutate_all(~0) %>%
  mutate(chris=1,nico=1,kirsten=-1,cate=-1) %>%
  add_epred_draws(m1) %>%
  ggplot(aes(
    x=.epred
  )) +
  stat_halfeye()
  
