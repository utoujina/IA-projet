const cases = document.querySelectorAll('.case');
const session3 = pl.create();
var rootUrl = window.location.origin;
var prologUrl = rootUrl + "/static/prolog/ia.pl"; 
session3.consult(prologUrl);

function generate_chance_card() {
    const ensemble = [-3, -2, -1, 1, 2, 3];
    const indice = Math.floor(Math.random() * ensemble.length);
    chance_number = ensemble[indice];
    return chance_number;
}

function format_query_chance() {
    chance_card = generate_chance_card();
    
    var decodedQuery = document.createElement("textarea");
    decodedQuery.innerHTML = pl_query;
    var queryWithQuotes = decodedQuery.value;
        
    // Séparer la requête en parties
    const parts = queryWithQuotes.match(/\[.*?\]|[^[\]\s,]+/g);

    // Modifications des derniers arguments
    parts[parts.length - 2] = chance_card;
    parts[parts.length - 4] = parts[parts.length-4] + "]";
    
    // Ajout des virgules
    const formattedQuery = parts.slice(1, parts.length).join(", ");
    return parts[0] + formattedQuery;
}

document.getElementById("button_générer").addEventListener("click", function(event){
    event.preventDefault();
    
    query_pl = format_query_chance();
    console.log(query_pl);
    
    session3.query(query_pl);
    
    session3.answer(x => {
        var IA_case = x.links.Couloir;
        var case_chosen = null;
        console.log(IA_case);
        if (IA_case == 0) {
            case_chosen = "gauche";
        }
        if (IA_case == 1){
            case_chosen = "milieu";
        }
        if(IA_case == 2){
            case_chosen = "droite";
        }
        
        displayMessage("TBot : Le joueur a tiré la carte chance " + chance_number + " secondes et l'a placé dans la case de " + case_chosen + ".");
        displayMessage("TBot : Appuyez sur suivant pour continuer.");
        
        // Envoyer le résultat
        var formData = new FormData();
        formData.append('chance_card', chance_number);
        formData.append('case', IA_case);
        
        fetch('/chance', {
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
    var button_suivant = document.getElementById('button_suivant');
    var button_générer = document.getElementById('button_générer');

    button_suivant.style.pointerEvents = 'auto';
    button_générer.style.pointerEvents = 'none';
    button_suivant.style.opacity = "1";
    button_générer.style.opacity = "0.5"; 
});