
% Base de connaissances pour des réponses simples
repondre("puis-je dépasser au-dessus d’un groupe de coureurs ?", "oui, il est permis de dépasser par le bas-côté de la route pour autant que le coureur arrive sur une case non occupée. si ce n’est pas le cas, le coureur chute et entraîne dans sa chute le groupe de coureurs qu’il voulait dépasser.").
repondre("je joue pour le 3e coureur de l’équipe d’italie. quelle carte de 12 secondes me conseillez-vous de jouer ?", "la carte de 12 secondes.").

% Règle par défaut pour les questions non traitées
repondre(_, "désole, ma base de données n’est pas assez complète pour le moment pour repondre à cette question.").
