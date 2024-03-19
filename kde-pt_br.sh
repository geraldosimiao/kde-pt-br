#!/bin/bash

# ****************************************************************************
# *   kde-pt_br - A tool for KDE's Brazilian Translation Team                *
# *   Copyright (C) 2007 by Diniz Bortolotto (diniz.bb@gmail.com)            *
# *   Copyright (C) 2008/2009/2014 by Fernando Boaglio (boaglio@kde.org)     *
# *   Copyright (C) 2019 by Frederico G. Guimarães (frederico@teia.bio.br)   *
# *   Copyright (C) 2023 by Luiz F. Ranghetti (elchevive@opensuse.org)       *
# *   Copyright (C) 2024 by Geraldo Simião (geraldosimiao@fedoraproject.org) *
# *   Copyright (C) 2024 by Frederico G. Guimarães (frederico@teia.bio.br)   *
# *                                                                          *
# *   This program is free software; you can redistribute it and/or modify   *
# *   it under the terms of the GNU General Public License as published by   *
# *   the Free Software Foundation; either version 2 of the License, or      *
# *   (at your option) any later version.                                    *
# *                                                                          *
# *   This program is distributed in the hope that it will be useful,        *
# *   but WITHOUT ANY WARRANTY; without even the implied warranty of         *
# *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the          *
# *   GNU General Public License for more details.                           *
# *                                                                          *
# *   You should have received a copy of the GNU General Public License      *
# *   along with this program; if not, write to the                          *
# *   Free Software Foundation, Inc.,                                        *
# *   59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.              *
# ****************************************************************************

echo -e "
=====================================================================
Este script tem por objetivo automatizar o processo de download e
atualização da cópia de trabalho do repositório de traduções.

Se for a primeira vez que você o executa, ele fará uma série de
perguntas para efetuar a configuração do Subversion e do Lokalize. Em
seguida, ele criará o ambiente de trabalho. Se você já o executou
anteriormente, ele recuperará as configurações salvas e fará a
atualização do repositório do Subversion.

Caso você queira relatar algum erro no script ou fazer alguma
sugestão de melhoria, não hesite em mandar um e-mail para a lista de
discussão (kde-i18n-pt_br@kde.org)
====================================================================="

# Verifica se o Subversion está instalado na máquina
if [ ! -x "$(command -v svn)" ];
then
    echo -e "\n====================================================================="
    echo -e "O software \"Subversion\" é necessário para o funcionamento desse"
    echo -e "script, mas ele não está instalado nesse sistema."
    echo -e "\nPor favor, instale-o e execute o script novamente."
    echo -e "=====================================================================\n"

    exit 1
fi

# Verifica se existe o arquivo de configurações
if [ -f $HOME/.config/kde-l10n-ptbr ];
then
    configurado=1
fi

# Verifica se o arquivo de configurações não existe
if [ -z "$configurado" ];
then

    # Caso não exista, coleta as informações iniciais, constrói a estrutura
    # de diretórios, faz o checkout do Subversion e cria os arquivos de
    # configuração
    echo -e "\nNão encontrei o arquivo com as configurações de tradução.\n"

    # Verifica se foi digitado S, s, N ou n
    while [[ ! "$primeira_vez" =~ [SsNn] ]];
    do
        read -p "É a primeira vez que você executa esse script? (S/N) " primeira_vez
    done

    # Instruções caso o arquivo de configurações não tenha sido encontrado e
    # não seja a primeira vez que o script foi executado
    case $primeira_vez in
     n|N)
        echo -e "\nPor favor, procure pelo arquivo \"kde-l10n-ptbr\" entre os seus"
        echo -e "arquivos e mova-o para o diretório \"$HOME/.config\"."
        echo -e "\nCaso não encontre o arquivo, execute esse script novamente e"
        echo -e "selecione a opção \"S\" para que o arquivo seja criado."

        exit 1
     ;;

     # Caso seja a primeira vez, o script continua
     s|S)
        echo -e "\n====================================================================="
        echo -e "Agora você deverá informar alguns parâmetros necessários para a"
        echo -e "configuração do seu ambiente de tradução."
        echo -e "\nEssas informações servirão para gerar o arquivo de configurações do"
        echo -e "Lokalize e serão incluídas nos arquivos que você traduzir."
        echo -e "=====================================================================\n"
     ;;
    esac

    while [[ ! $dadosok =~ [Ss] ]]
    do

        while [[ $nome == '' ]]
        do
            read -p "Digite o seu nome: " nome
        done

        while [[ $email == '' ]]
        do
            read -p "Digite o seu endereço de e-mail: " email
        done

        echo -e "\n====================================================================="
        echo -e "Todos podem baixar os arquivos de tradução, mas somente usuários com"
        echo -e "privilégios de desenvolvedor podem enviar as alterações feitas.\n"

        while [[ ! $desenvolvedor =~ [SsNn] ]]
        do
            read -p "Você tem uma conta com privilégios de desenvolvedor? (S/N)" desenv
            desenvolvedor=${desenv^}
        done

        echo -e "\n====================================================================="
        echo -e "\nPor favor, confira as informações digitadas:"
        echo -e "- Nome: $nome"
        echo -e "- E-mail: $email"
        echo -e "- Possui conta de desenvolvedor? $desenvolvedor\n"
        echo -e "=====================================================================\n"

        while [[ ! $dadosok =~ [SsNn] ]]
        do
            read -p "As informações estão corretas? (S/N) " dadosok
        done

        if [[ $dadosok =~ [Nn] ]];
        then
            unset nome
            unset email
            unset desenvolvedor
            unset dadosok
            echo -e "\n====================================================================="
            echo -e "Por favor, digite novamente os seus dados.\n"
        fi

    done

    # Constrói os diretórios para receber os arquivos
    echo -e "\n====================================================================="
    echo -e "Em qual diretório você deseja baixar os arquivos de tradução?"
    echo -e "Por favor, digite o caminho completo.\n"
    echo -e "Caso você deixe em branco, a estrutura será criada dentro de\n"
    echo -e "\"$HOME/kde-l10n/\".\n"

    read -p "-> " raiz;

    if [ -z "$raiz" ];
    then
        raiz=$HOME/kde-l10n
    fi

    # Define e cria os diretórios locais
    stable5=$raiz/stable/l10n-kf5
    stable6=$raiz/stable/l10n-kf6
    trunk5=$raiz/trunk/l10n-kf5
    trunk6=$raiz/trunk/l10n-kf6

    echo -e "\n====================================================================="
    echo -e "Criando os diretórios de trabalho..."
    echo -e "=====================================================================\n"
    mkdir -p $stable5
    mkdir -p $stable6
    mkdir -p $trunk5
    mkdir -p $trunk6

    # Monta as variáveis utilizadas no checkout/update do Subversion,
    # dependendo do usuário ter ou não uma conta de desenvolvedor
    if [[ $desenvolvedor == "S" ]]
    then
        varsvn="svn+ssh://svn@svn.kde.org/home/kde"

        # Ativa o agente SSH e registra a senha para que ela seja digitada
        # somente uma vez
        echo -e "\n====================================================================="
        echo -e "- Ativando agente SSH\n"
        eval `ssh-agent`
        echo -e "\n- Registrando senha SSH\n"
        ssh-add
        echo -e "=====================================================================\n"

    elif  [[ $desenvolvedor == "N" ]]
    then
        varsvn="svn://anonsvn.kde.org/home/kde"
    fi

    # Entra em cada um dos diretórios e faz o checkout inicial dos arquivos
    cd $stable5

    echo -e "\n====================================================================="
    echo -e "Recebendo arquivos template do ramo stable5"
    echo -e "=====================================================================\n"

    svn checkout $varsvn/branches/stable/l10n-kf5/templates

    echo -e "\n====================================================================="
    echo -e "Recebendo arquivos do ramo stable5"
    echo -e "=====================================================================\n"

    svn checkout $varsvn/branches/stable/l10n-kf5/pt_BR

    cd $stable6

    echo -e "\n====================================================================="
    echo -e "Recebendo arquivos template do ramo stable6"
    echo -e "=====================================================================\n"

    svn checkout $varsvn/branches/stable/l10n-kf6/templates

    echo -e "\n====================================================================="
    echo -e "Recebendo arquivos do ramo stable6"
    echo -e "=====================================================================\n"

    svn checkout $varsvn/branches/stable/l10n-kf6/pt_BR

    cd $trunk5

    echo -e "\n====================================================================="
    echo -e "Recebendo arquivos templates do trunk5"
    echo -e "=====================================================================\n"

    svn checkout $varsvn/trunk/l10n-kf5/templates

    echo -e "\n====================================================================="
    echo -e "Recebendo arquivos do trunk5"
    echo -e "=====================================================================\n"

    svn checkout $varsvn/trunk/l10n-kf5/pt_BR

    cd $trunk6

    echo -e "\n====================================================================="
    echo -e "Recebendo arquivos templates do trunk6"
    echo -e "=====================================================================\n"

    svn checkout $varsvn/trunk/l10n-kf6/templates

    echo -e "\n====================================================================="
    echo -e "Recebendo arquivos do trunk6"
    echo -e "=====================================================================\n"

    svn checkout $varsvn/trunk/l10n-kf6/pt_BR

    echo -e "\n====================================================================="
    echo -e "Gerando arquivo de configuração"
    echo -e "=====================================================================\n"

    # Caso seja conexão autenticada, retira a senha do cache e encerra o
    # agente SSH
    if [[ $desenvolvedor == "S" ]]
    then
        echo -e "\n====================================================================="
        echo -e "- Retirando senha SSH do cache\n"
        ssh-add -d
        echo -e "\n- Encerrando Agente SSH\n"
        ssh-agent -k
        echo -e "=====================================================================\n"
    fi

    # Vai para o diretório ~/.config e gera o arquivo de configurações
    cd $HOME/.config

    echo -e "# Esse arquivo contém as informações para a criação do arquivo de" > kde-l10n-ptbr
    echo -e "# configurações do projeto de tradução para pt-BR no Lokalize," >> kde-l10n-ptbr
    echo -e "# bem como informações para o script de download do ambiente de" >> kde-l10n-ptbr
    echo -e "# tradução.\n" >> kde-l10n-ptbr
    echo -e "raiz=$raiz" >> kde-l10n-ptbr
    echo -e "nome=$nome" >> kde-l10n-ptbr
    echo -e "email=$email" >> kde-l10n-ptbr
    echo -e "desenvolvedor=$desenvolvedor" >> kde-l10n-ptbr

    # Vai para o diretório $raiz para criar os arquivos de projetos do Lokalize
    cd $raiz

    # Cria o arquivo para o ramo stable5
    echo -e "[General]" > index-stable5.lokalize
    echo -e "BranchDir=trunk/l10n-kf5/pt_BR" >> index-stable5.lokalize
    echo -e "GlossaryTbx=" >> index-stable5.lokalize
    echo -e "LangCode=pt_BR" >> index-stable5.lokalize
    echo -e "LanguageSource=Project" >> index-stable5.lokalize
    echo -e "MailingList=kde-i18n-pt_BR@kde.org" >> index-stable5.lokalize
    echo -e "PoBaseDir=stable/l10n-kf5/pt_BR" >> index-stable5.lokalize
    echo -e "PotBaseDir=stable/l10n-kf5/templates" >> index-stable5.lokalize
    echo -e "ProjLangTeam=Brazilian Portuguese <kde-i18n-pt_BR@kde.org>" >> index-stable5.lokalize
    echo -e "ProjectID=kde-pt_BR" >> index-stable5.lokalize
    echo -e "TargetLangCode=pt_BR" >> index-stable5.lokalize

    # Cria o arquivo para o ramo stable6
    echo -e "[General]" > index-stable6.lokalize
    echo -e "BranchDir=trunk/l10n-kf6/pt_BR" >> index-stable6.lokalize
    echo -e "GlossaryTbx=" >> index-stable6.lokalize
    echo -e "LangCode=pt_BR" >> index-stable6.lokalize
    echo -e "LanguageSource=Project" >> index-stable6.lokalize
    echo -e "MailingList=kde-i18n-pt_BR@kde.org" >> index-stable6.lokalize
    echo -e "PoBaseDir=stable/l10n-kf6/pt_BR" >> index-stable6.lokalize
    echo -e "PotBaseDir=stable/l10n-kf6/templates" >> index-stable6.lokalize
    echo -e "ProjLangTeam=Brazilian Portuguese <kde-i18n-pt_BR@kde.org>" >> index-stable6.lokalize
    echo -e "ProjectID=kde-pt_BR" >> index-stable6.lokalize
    echo -e "TargetLangCode=pt_BR" >> index-stable6.lokalize

    # Cria o arquivo para o trunk5
    echo -e "[General]" > index-trunk5.lokalize
    echo -e "BranchDir=stable/l10n-kf5/pt_BR" >> index-trunk5.lokalize
    echo -e "GlossaryTbx=" >> index-trunk5.lokalize
    echo -e "LangCode=pt_BR" >> index-trunk5.lokalize
    echo -e "LanguageSource=Project" >> index-trunk5.lokalize
    echo -e "MailingList=kde-i18n-pt_BR@kde.org" >> index-trunk5.lokalize
    echo -e "PoBaseDir=trunk/l10n-kf5/pt_BR" >> index-trunk5.lokalize
    echo -e "PotBaseDir=trunk/l10n-kf5/templates" >> index-trunk5.lokalize
    echo -e "ProjLangTeam=Brazilian Portuguese <kde-i18n-pt_BR@kde.org>" >> index-trunk5.lokalize
    echo -e "ProjectID=kde-pt_BR" >> index-trunk5.lokalize
    echo -e "TargetLangCode=pt_BR" >> index-trunk5.lokalize

    # Cria o arquivo para o trunk6
    echo -e "[General]" > index-trunk6.lokalize
    echo -e "BranchDir=stable/l10n-kf6/pt_BR" >> index-trunk6.lokalize
    echo -e "GlossaryTbx=" >> index-trunk6.lokalize
    echo -e "LangCode=pt_BR" >> index-trunk6.lokalize
    echo -e "LanguageSource=Project" >> index-trunk6.lokalize
    echo -e "MailingList=kde-i18n-pt_BR@kde.org" >> index-trunk6.lokalize
    echo -e "PoBaseDir=trunk/l10n-kf6/pt_BR" >> index-trunk6.lokalize
    echo -e "PotBaseDir=trunk/l10n-kf6/templates" >> index-trunk6.lokalize
    echo -e "ProjLangTeam=Brazilian Portuguese <kde-i18n-pt_BR@kde.org>" >> index-trunk6.lokalize
    echo -e "ProjectID=kde-pt_BR" >> index-trunk6.lokalize
    echo -e "TargetLangCode=pt_BR" >> index-trunk6.lokalize

    echo -e "\n====================================================================="
    echo -e "A configuração foi concluída e a cópia local do repositório de"
    echo -e "traduções foi baixada.\n"
    echo -e "Foram gerados quatro arquivos de configuração para serem utilizados no"
    echo -e "Lokalize. Todos se encontram no diretório:\n"
    echo -e "$raiz\n"
    echo -e "- \"index-stable5.lokalize\": para traduções do ramo \"stable5\";\n"
    echo -e "- \"index-stable6.lokalize\": para traduções do ramo \"stable6\";\n"
    echo -e "- \"index-trunk5.lokalize\": para traduções do \"trunk5\";\n"
    echo -e "- \"index-trunk6.lokalize\": para traduções do \"trunk6\".\n"
    echo -e "Esses arquivos devem ser abertos a partir do menu \"Projeto\" no"
    echo -e "Lokalize, selecionando a opção \"Abrir projeto...\".\n"
    echo -e "Boas traduções!!!"
    echo -e "=====================================================================\n"

else

    # Caso exista o arquivo de configurações, o script, busca, nesse
    # arquivo, em qual diretório estão os arquivos locais
    raiz=$(grep "raiz" $HOME/.config/kde-l10n-ptbr | cut -f2 -d"=")
    desenvolvedor=$(grep "desenvolvedor" $HOME/.config/kde-l10n-ptbr | cut -f2 -d"=")

    if [ ! -d "$raiz" ];
    then
        echo -e "\n====================================================================="
        echo -e "O arquivo de configurações da tradução foi encontrado, mas o diretório"
        echo -e "onde deveriam estar as traduções, não. O diretório configurado é:\n"
        echo -e "$raiz\n"
        echo -e "Você tem duas opções:\n"
        echo -e "1) Excluir o arquivo:"
        echo -e "   $HOME/.config/kde-l10n-ptbr"
        echo -e "   e executar o script novamente. A configuração será refeita e o"
        echo -e "   a cópia local será baixada. Essa é a opção mais simples.\n"
        echo -e "2) Editar o arquivo:"
        echo -e "   $HOME/.config/kde-l10n-ptbr"
        echo -e "   e alterar o valor da variável \"raiz\" para o diretório onde"
        echo -e "   está a cópia local dos arquivos de tradução. Só execute esse"
        echo -e "   procedimento se tiver certeza do que está fazendo. Em caso de"
        echo -e "   dúvida, execute o procedimento 1"
        echo -e "=====================================================================\n"

        exit 1
    fi

    # Define as variáveis dos diretórios locais
    stable5=$raiz/stable/l10n-kf5
    stable6=$raiz/stable/l10n-kf6
    trunk5=$raiz/trunk/l10n-kf5
    trunk6=$raiz/trunk/l10n-kf6

    echo -e "\n====================================================================="
    echo -e "O arquivo de configurações da tradução foi encontrado."
    echo -e "Será realizada a atualização da cópia local do repositório de"
    echo -e "traduções, que está localizado no diretório:"
    echo -e "$raiz"
    echo -e "=====================================================================\n"

    # Ativa o agente SSH e registra a senha para que ela seja digitada
    # somente uma vez, caso o usuário tenha uma conta de desenvolvedor
    if [[ $desenvolvedor=="S" ]]
    then
        echo -e "\n====================================================================="
        echo -e "- Ativando agente SSH\n"
        eval `ssh-agent`
        echo -e "\n- Registrando senha SSH\n"
        ssh-add
        echo -e "=====================================================================\n"
    fi

    # Entra em cada um dos diretórios e faz o checkout inicial dos arquivos
    cd $stable5

    echo -e "\n====================================================================="
    echo -e "Recebendo arquivos template do ramo stable5"
    echo -e "=====================================================================\n"

    svn update templates

    echo -e "\n====================================================================="
    echo -e "Recebendo arquivos do ramo stable5"
    echo -e "=====================================================================\n"

    svn update pt_BR

    cd $stable6

    echo -e "\n====================================================================="
    echo -e "Recebendo arquivos template do ramo stable6"
    echo -e "=====================================================================\n"

    svn update templates

    echo -e "\n====================================================================="
    echo -e "Recebendo arquivos do ramo stable6"
    echo -e "=====================================================================\n"

    svn update pt_BR

    cd $trunk5

    echo -e "\n====================================================================="
    echo -e "Recebendo arquivos templates do trunk5"
    echo -e "=====================================================================\n"

    svn update templates

    echo -e "\n====================================================================="
    echo -e "Recebendo arquivos do trunk5"
    echo -e "=====================================================================\n"

    svn update pt_BR

    cd $trunk6

    echo -e "\n====================================================================="
    echo -e "Recebendo arquivos templates do trunk6"
    echo -e "=====================================================================\n"

    svn update templates

    echo -e "\n====================================================================="
    echo -e "Recebendo arquivos do trunk6"
    echo -e "=====================================================================\n"

    svn update pt_BR

    if [[ $desenvolvedor=="S" ]]
    then
        # Retira a senha do cache e encerra o agente SSH
        echo -e "\n====================================================================="
        echo -e "- Retirando senha SSH do cache\n"
        ssh-add -d
        echo -e "\n- Encerrando Agente SSH\n"
        ssh-agent -k
        echo -e "=====================================================================\n"
    fi

    echo -e "\n====================================================================="
    echo -e "A atualização da cópia local do repositório de traduções foi concluída.\n"
    echo -e "Lembre-se que existem dois arquivos de configuração para serem"
    echo -e "utilizados no Lokalize. Ambos se encontram no diretório:\n"
    echo -e "$raiz:\n"
    echo -e "O arquivo \"index-stable.lokalize\" deve ser usado quando se for"
    echo -e "efetuar traduções no ramo \"stable\". Já o \"index-trunk.lokalize\""
    echo -e "deve ser usaddo para traduções do \"trunk\"."\n
    echo -e "Esses arquivos devem ser abertos a partir do menu \"Projeto\" no"
    echo -e "Lokalize, selecionando a opção \"Abrir projeto...\".\n"
    echo -e "Boas traduções!!!"
    echo -e "=====================================================================\n"

fi
