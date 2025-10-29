#Requires AutoHotkey v2.0
SendMode "Input"
A_CoordModeMouse := "Screen"

; ---------------------------
; Variáveis Globais
; ---------------------------
global hud := ""
global hudStatusText := ""
global g_shouldStop := false ; Variável para controlar a interrupção

; ---------------------------
; Criação do HUD
; ---------------------------
CreateHUD() {
    global hud, hudStatusText
    ; Cria um HUD simples, sem borda, sempre no topo
    hud := Gui("+AlwaysOnTop -Caption +ToolWindow")
    hud.BackColor := "000000"
    hud.SetFont("s12 Bold", "Segoe UI")
    hudStatusText := hud.Add("Text", "x10 y10 w300 c00FF00", "AGUARDANDO COMANDO")
    
    hud.Show("x10 y10 w320 h40 NA")
    WinSetTransparent(200, hud)
    OnMessage(0x201, MoveHUD_WM) ; Permite mover o HUD com o mouse
}

; ---------------------------
; Funções
; ---------------------------
MoveHUD_WM(wParam, lParam, msg, hwnd) {
    global hud
    ; Se o clique for na janela do HUD, inicia o arraste
    if (hwnd = hud.Hwnd) {
        PostMessage(0xA1, 2, 0) ; WM_NCLBUTTONDOWN, HTCAPTION
    }
}

PerformDrag(startX, startY, endX, endY) {
    ; Função auxiliar que realiza a ação de arrastar
    dragSpeed := 5 ; Velocidade do arraste (0=instantâneo, 100=lento)


    MouseMove(startX, startY, 0)
    Sleep(1500)
    MouseClick("Left", , , , , "D")
    Sleep(50)
    MouseMove(endX, endY, dragSpeed)
    MouseClick("Left", , , , , "U")
    
}

UpdateHUD(newText) {
    global hudStatusText
    if IsObject(hudStatusText) && (Type(hudStatusText) = "Gui.Text") {
        hudStatusText.Text := newText
    }
}

OrganizeSkillsFunc(*) {
    global hudStatusText, g_shouldStop

    g_shouldStop := false ; Reseta o sinal de parada no início da execução

    ; Procura por todas as janelas do Dofus abertas
    dofusWindows := WinGetList("ahk_exe Dofus.exe")
    if (dofusWindows.Length = 0) {
        ; Garante que hudStatusText é um objeto antes de usá-lo
        UpdateHUD("Nenhuma janela do Dofus encontrada.")
        Sleep(2000)
        UpdateHUD("AGUARDANDO COMANDO")
        Return
    }

    totalWindows := dofusWindows.Length

    ; Lista de todas as skills a serem organizadas
    skills := [
        {startX: 1522, startY: 609, endX: 689, endY: 965},  ; Skill 1
        {startX: 1333, startY: 335, endX: 735, endY: 967},  ; Skill 2
        {startX: 1457, startY: 390, endX: 778, endY: 966},  ; Skill 3
        {startX: 1335, startY: 660, endX: 820, endY: 964},  ; Skill 4
        {startX: 1524, startY: 773, endX: 866, endY: 967},  ; Skill 5
        {startX: 1454, startY: 444, endX: 909, endY: 964},  ; Skill 6
        {startX: 1261, startY: 441, endX: 954, endY: 969},  ; Skill 7
        {startX: 1262, startY: 717, endX: 995, endY: 969},  ; Skill 8
        {startX: 1262, startY: 389, endX: 1082, endY: 965}, ; Skill 9
        {startX: 1525, startY: 554, endX: 1126, endY: 969}, ; Skill 10
        {startX: 1263, startY: 877, endX: 1169, endY: 969}, ; Skill 11
        {startX: 1524, startY: 828, endX: 690, endY: 1010}, ; Skill 12
        {startX: 1264, startY: 498, endX: 732, endY: 1009}, ; Skill 13
        {startX: 1264, startY: 826, endX: 781, endY: 1010}, ; Skill 14
        {startX: 1522, startY: 333, endX: 819, endY: 1008}, ; Skill 15
        {startX: 1264, startY: 606, endX: 863, endY: 1012}, ; Skill 16
        {startX: 1264, startY: 553, endX: 909, endY: 1013}, ; Skill 17
        {startX: 1524, startY: 879, endX: 954, endY: 1010}, ; Skill 18
        {startX: 1456, startY: 497, endX: 994, endY: 1009}, ; Skill 19
        {startX: 1264, startY: 775, endX: 1126, endY: 1012}, ; Skill 20
        {startX: 1521, startY: 665, endX: 1167, endY: 1011}  ; Skill 21
    ]

    totalSkills := skills.Length

    ; --- FASE DE PREPARAÇÃO: Clicar em todas as skills em todas as janelas ---
    UpdateHUD("Preparando... Clicando nas skills")
    Sleep(200)

    ; Loop para percorrer cada JANELA na fase de preparação
    for winIndex, hwnd in dofusWindows {
        ; Ativa a janela atual
        WinActivate("ahk_id " . hwnd)
        WinWaitActive("ahk_id " . hwnd, , 1)

        ; Loop para clicar em cada SKILL na janela atual
        for skillIndex, skill in skills {
            if (g_shouldStop) {
                break 2
            }

            UpdateHUD("Preparando Janela " . winIndex . "/" . totalWindows . " - Skill " . skillIndex . "/" . totalSkills)
            
            ; Clica na posição inicial da skill para garantir que ela esteja visível/disponível
            MouseClick("Left", skill.startX, skill.startY)
            Sleep(550) ; Pequena pausa entre os cliques
        }

        if (g_shouldStop) {
            break
        }
    }

    ; Se o script foi interrompido durante a preparação, encerra a função
    if (g_shouldStop) {
        Return ; A função StopScript já cuida da mensagem do HUD
    }

    ; Loop principal para percorrer cada JANELA
    for winIndex, hwnd in dofusWindows {
        ; Ativa a janela atual para garantir que os cliques sejam enviados a ela
        WinActivate("ahk_id " . hwnd)
        WinWaitActive("ahk_id " . hwnd, , 1) ; Espera até 1 segundo pela janela ficar ativa

        ; Loop secundário para aplicar cada SKILL na janela atual
        for skillIndex, skill in skills {
            ; Verifica se a interrupção foi solicitada
            if (g_shouldStop) {
                break 2 ; Sai de ambos os loops (janelas e skills)
            }

            ; Atualiza o HUD com o progresso
            UpdateHUD("Janela " . winIndex . "/" . totalWindows . " - Skill " . skillIndex . "/" . totalSkills)

            
            ; Executa a ação de arrastar
            PerformDrag(skill.startX, skill.startY, skill.endX, skill.endY)

            ; Pausa para o jogo processar antes de mudar de skill
            Sleep(200)
        }

        ; Se o script foi interrompido, sai do loop de janelas também
        if (g_shouldStop) {
            break
        }

        ; Organiza a skill especial após todas as outras na janela atual
        UpdateHUD("Janela " . winIndex . "/" . totalWindows . " - Skill Especial")
        MouseClick("Left", 1423, 196) ; Clica para habilitar a skill especial
        Sleep(500) ; Espera a interface atualizar
        PerformDrag(1394, 334, 1041, 1010) ; Arraste da skill especial

        ; Pausa maior antes de mudar para a próxima janela
        Sleep(500)
    }

    ; Atualiza o HUD ao finalizar
    if (g_shouldStop) {
        ; Se o script foi interrompido
        UpdateHUD("CANCELADO!")
    } else {
        ; Se o script concluiu normalmente
        UpdateHUD("CONCLUÍDO!")
    }
    Sleep(2000)
    UpdateHUD("AGUARDANDO COMANDO")
}

StopScript() {
    global g_shouldStop, hudStatusText
    g_shouldStop := true
    UpdateHUD("CANCELANDO...")
}

; ---------------------------
; Hotkeys (Fixos)
; ---------------------------
F3::OrganizeSkillsFunc()
F4::StopScript()
; ---------------------------
; Inicialização
; ---------------------------
CreateHUD()
