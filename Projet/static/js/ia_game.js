const session2 = pl.create();
var rootUrl = window.location.origin;
var prologUrl = rootUrl + "/static/prolog/ia.pl"; 
session2.consult(prologUrl);

function select_card(IA_choice){
    var attribu = '.value[value="' + IA_choice + '"]';
    var card_selected = document.querySelector(attribu);
    if (card_selected) {
        card_selected.parentElement.classList.toggle('selected');
    } else {
        console.log("Aucune carte avec la valeur " + IA_choice + " n'a été trouvée.");
    }
}

document.getElementById("button_submit").addEventListener("click", function(event){
    event.preventDefault();
    
    var decodedQuery = document.createElement("textarea");
    decodedQuery.innerHTML = pl_query;
    var queryWithQuotes = decodedQuery.value;
    
    session2.query(queryWithQuotes);
    
    session2.answer(x => {
        var IA_case = x.links.C;
        var IA_card = x.links.X;
        var case_chosen = null;
        
        if (IA_case == 0) {
            case_chosen = "gauche";
        }
        if (IA_case == 1){
            case_chosen = "milieu";
        }
        if(IA_case == 2){
            case_chosen = "droite";
        }
        
        displayMessage("TBot : L'IA a avancé son joueur de " + IA_card + " secondes et l'a placé dans la case de " + case_chosen + ".");
        displayMessage("TBot : Appuyez sur suivant pour continuer.");
        select_card(IA_card);
        
        // Envoyer le résultat
        var formData = new FormData();
        formData.append('card', IA_card);
        formData.append('case', IA_case);
        
        fetch('/choice', {
            method: 'POST',
            body: formData
        })
        .then((response) => response.json())
        .then((data) => {
            console.log(data);
        })
        .catch((error) => {
            console.log(error);
        });
    });
    
    // Mettre à jour les boutons
    button_suivant.style.pointerEvents = 'auto';
    button_submit.style.pointerEvents = 'none';
    button_suivant.style.opacity = "1";
    button_submit.style.opacity = "0.5";
});
