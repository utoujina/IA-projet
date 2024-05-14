const cases = document.querySelectorAll('.case');
let chance_number = 0;

// Déséllectionne les élément sauf celui en paramètre
function deselectExcept(selectedElement, elements) {
    elements.forEach(element => {
        if (element !== selectedElement) {
            element.classList.remove('selected');
        }
    });
}

// Event pour les cases
cases.forEach(caseElement => {
    caseElement.addEventListener('click', () => {
        deselectExcept(caseElement, cases);
        caseElement.classList.toggle('selected');
        
    });
});

// fonction d'envoie des données
document.getElementById("button_appliquer").addEventListener("click", function(event){
    event.preventDefault();
    
    const case_selected = document.querySelector('.case.selected');
    
    if(case_selected){
        var case_value = case_selected.querySelector('.value').getAttribute('value');
        
        // Envoyer le résultat
        var formData = new FormData();
        formData.append('chance_card', chance_number);
        formData.append('case', case_value);
        
        fetch('/Chance', {
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
        
        // Mettre à jour les boutons
        var button_suivant = document.getElementById('button_suivant');
        var button_appliquer = document.getElementById('button_appliquer');
        
        button_suivant.style.pointerEvents = 'auto';
        button_appliquer.style.pointerEvents = 'none';
        button_suivant.style.opacity = "1";
        button_appliquer.style.opacity = "0.5";
        
        case_chosen = null;
        if (case_value == 0) {
            case_chosen = "gauche";
        }
        if (case_value == 1){
            case_chosen = "milieu";
        }
        if(case_value == 2){
            case_chosen = "droite";
        }
        
        displayMessage("TBot : Vous avez choisit de déplacer votre joueur sur la case de " + case_chosen +".");
        displayMessage("TBot : Appuyez sur suivant pour continuer.");   
    }
    else{
        alert("Veuillez sélectionner une case.");
    }
    
});

document.getElementById("button_générer").addEventListener("click", function(event){
    event.preventDefault();
    
    const ensemble = [-3, -2, -1, 1, 2, 3];
    const indice = Math.floor(Math.random() * ensemble.length);
    chance_number = ensemble[indice];
    console.log(chance_number);
    
    displayMessage("TBot : Votre équipe a tiré la carte chance " + chance_number + " secondes !");
    displayMessage("TBot : Appuyer sur appliquer lorsque vous aurez choisi le couloir sur lequel placer votre coureur.");
    
    // Mettre à jour les boutons
    var button_générer = document.getElementById('button_générer');
    var button_appliquer = document.getElementById('button_appliquer');
    
    button_appliquer.style.pointerEvents = 'auto';
    button_générer.style.pointerEvents = 'none';
    button_appliquer.style.opacity = "1";
    button_générer.style.opacity = "0.5";
    
    cases.forEach(caseElement => {
        caseElement.classList.remove('unactionable');
    })    
});

// envent pour couloir indisponnible
function indisponnible_case() {
    const card_selected = document.querySelector('.card.selected');
    
    if (card_selected) {
        const card_value = card_selected.querySelector('.value').getAttribute('value');
        const current_case2 = JSON.parse(current_case);
        const caseDispo = get_available_case(current_case2, card_value);
        
        console.log(caseDispo)
        
        cases.forEach(caseElement => {
            const case_col = caseElement.querySelector('.value');
            const value_case_col = case_col.getAttribute('value');

            if (!caseDispo.includes(parseInt(value_case_col))) {
                caseElement.classList.add('unactionable');
                caseElement.classList.remove('selected');
                
            } else {
                caseElement.classList.remove('unactionable');
            }
        });
    }
}

// Fonction renvoyant la liste des couloir disponibles
function get_available_case(box, card) {
    let box_to_reach = parseInt(box[0]) + parseInt(card);
    
    if (card === 1) {
        if (box[1] === 0) {
            return [0, 1];
            
        } else if (box[1] === 2) {
            return [1, 2];
            
        } else if (box[1] === 1) {
            return [0, 1, 2];
        }
    } else {
        if (box_to_reach > 0 && box_to_reach < 11) {
            return [0, 1, 2];
        } else if (box_to_reach > 10 && box_to_reach < 19) {
            return [0, 2];
        } else if (box_to_reach > 18 && box_to_reach < 22) {
            return [0, 1, 2];
        } else if (box_to_reach > 21 && box_to_reach < 36) {
            if (box[0] < 22) {
                return [0, 1, 2];
            } else {
                if (box[1] === 2) {
                    return [2];
                } else {
                    return [0, 1];
                }
            }
        } else if (box_to_reach > 35 && box_to_reach < 73) {
            return [0, 2];
        } else if (box_to_reach > 72 && box_to_reach < 76) {
            return [0];
        } else if (box_to_reach > 75 && box_to_reach < 85) {
            return [0, 2];
        } else if (box_to_reach > 84 && box_to_reach < 95) {
            if (box[0] < 84) {
                return [0, 2];
            } else {
                return [box[1]];
            }
        } else if (box_to_reach > 94 && box_to_reach < 106) {
            return [0, 1, 2];
        }
    }
    
    return [-1];
}