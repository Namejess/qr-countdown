#!/bin/bash

# Configuration des couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Vérifier si xcodebuild est disponible
if ! command -v xcodebuild &> /dev/null; then
    error "xcodebuild n'est pas installé. Veuillez installer Xcode Command Line Tools."
    exit 1
fi

# Liste des projets à construire
# Format: "chemin/vers/projet.xcodeproj|scheme|configuration"
PROJECTS=(
    "Projet1/Projet1.xcodeproj|Projet1|Release"
    "Projet2/Projet2.xcodeproj|Projet2|Debug"
    # Ajoutez vos projets ici
)

# Créer un dossier pour les logs
LOG_DIR="build_logs"
mkdir -p "$LOG_DIR"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Fonction pour construire un projet
build_project() {
    local project_path=$1
    local scheme=$2
    local configuration=$3
    
    log "Construction de $scheme ($configuration) dans $project_path"
    
    # Construire le projet
    xcodebuild \
        -project "$project_path" \
        -scheme "$scheme" \
        -configuration "$configuration" \
        clean build \
        | tee "$LOG_DIR/${scheme}_${configuration}_${TIMESTAMP}.log"
    
    # Vérifier le statut de la construction
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        log "✅ Construction réussie pour $scheme"
        return 0
    else
        error "❌ Échec de la construction pour $scheme"
        return 1
    fi
}

# Compteur de succès/échecs
success_count=0
failure_count=0

# Construire tous les projets
for project_info in "${PROJECTS[@]}"; do
    IFS='|' read -r project_path scheme configuration <<< "$project_info"
    
    if build_project "$project_path" "$scheme" "$configuration"; then
        ((success_count++))
    else
        ((failure_count++))
    fi
done

# Afficher le résumé
echo -e "\n${GREEN}=== Résumé de la construction ===${NC}"
echo -e "Projets construits avec succès: ${GREEN}$success_count${NC}"
echo -e "Projets en échec: ${RED}$failure_count${NC}"
echo -e "Logs disponibles dans le dossier: ${YELLOW}$LOG_DIR${NC}"

# Retourner un code d'erreur si au moins un projet a échoué
if [ $failure_count -gt 0 ]; then
    exit 1
fi 