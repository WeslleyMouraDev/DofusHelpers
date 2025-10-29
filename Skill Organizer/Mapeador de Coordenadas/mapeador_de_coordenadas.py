import keyboard
import pyautogui
import time

skills = []
current_skill = None
running = True

print("=== Registro de Coordenadas de Skills ===")
print("F2 = Registrar início da skill atual")
print("F3 = Registrar fim da skill atual")
print("F4 = Finalizar e salvar em coordenadas_skills.txt\n")

while running:
    # Registrar coordenada inicial
    if keyboard.is_pressed("f2"):
        time.sleep(0.2)  # Evita múltiplos cliques rápidos
        if current_skill is not None and "final" not in current_skill:
            print("⚠️ Você ainda não registrou o final da última skill!")
            continue

        x, y = pyautogui.position()
        current_skill = {"inicio": (x, y)}
        skills.append(current_skill)
        print(f"Skill {len(skills)} - Início registrado em: {x}, {y}")
        time.sleep(0.5)

    # Registrar coordenada final
    if keyboard.is_pressed("f3"):
        time.sleep(0.2)
        if current_skill is None:
            print("⚠️ Primeiro registre o início com F2.")
            continue
        x, y = pyautogui.position()
        current_skill["final"] = (x, y)
        print(f"Skill {len(skills)} - Final registrado em: {x}, {y}")
        time.sleep(0.5)

    # Finalizar e salvar
    if keyboard.is_pressed("f4"):
        print("\nSalvando coordenadas em coordenadas_skills.txt...")
        with open("coordenadas_skills.txt", "w", encoding="utf-8") as f:
            for i, skill in enumerate(skills, start=1):
                f.write(f"Click inicial Skill {i}: {skill['inicio']}\n")
                if "final" in skill:
                    f.write(f"Click final Skill {i}: {skill['final']}\n")
                f.write("\n")
        print("✅ Arquivo salvo com sucesso!")
        running = False
        break

    time.sleep(0.05)
