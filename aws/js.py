import json
import sys

# Leer JSON desde la entrada estándar
try:
    input_data = sys.stdin.read()
    data = json.loads(input_data)

    # Iterar y formatear los datos
    for output in data:
        print("CommandId:", output.get("CommandId", []))
        print("Status:", output.get("Status", []))
        print("ResponseCode:", output.get("ResponseCode", []))
        print("Output:")
        for line in output.get("Output", []):
            print(line)
        print("\n" + "="*80 + "\n")

except json.JSONDecodeError as e:
    print(f"Error al decodificar JSON: {e}")
except Exception as e:
    print(f"Ocurrió un error: {e}")
