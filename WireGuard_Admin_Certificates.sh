#!/bin/bash

while true; do
    clear
    echo ""
    echo "=============================================="
    echo "    MENÚ DE GESTIÓN DE USUARIOS WIREGUARD     "
    echo "=============================================="
    echo "1) Crear claves para usuario VPN"
    echo "2) Comprobar usuario"
    echo "3) Borrar ficheros del usuario"
    echo "0|quit|exit) Salir"
    echo "=============================================="
    echo ""
    read -p "Seleccione una opción: " OPCION

    case "$OPCION" in
        1)
            read -p "Ingrese el nombre del usuario VPN: " USUARIO

            if [ -z "$USUARIO" ]; then
                echo "El nombre de usuario no puede estar vacío."
                read -n1 -r -p "Presione [Enter] para continuar..."
                continue
            fi

            RUTA="/etc/wireguard/clients/${USUARIO}"
            mkdir -p "$RUTA"
            wg genkey | tee "${RUTA}/${USUARIO}.key" > /dev/null
            cat "${RUTA}/${USUARIO}.key" | wg pubkey | tee "${RUTA}/${USUARIO}.pub" > /dev/null

            echo "Se han creado las claves para el usuario '${USUARIO}' en la ruta ${RUTA}."
            read -n1 -r -p "Presione [Enter] para continuar..."
            ;;

        2)
            read -p "Ingrese el nombre del usuario a comprobar: " USUARIO
            echo""

            if [ -z "$USUARIO" ]; then
                echo "El nombre de usuario no puede estar vacío."
                read -n1 -r -p "Presione [Enter] para continuar..."
                continue
            fi

            RUTA="/etc/wireguard/clients/${USUARIO}"

            if [ ! -d "$RUTA" ]; then
                echo "No existe ningún dato del usuario '${USUARIO}'."
            else
                KEY="${RUTA}/${USUARIO}.key"
                PUB="${RUTA}/${USUARIO}.pub"

                if [ -f "$KEY" ] && [ -f "$PUB" ]; then
                    echo "El usuario '${USUARIO}' tiene ficheros creados."
                    echo ""

                    # Verificar formato de la clave privada
                    if grep -qE '^[A-Za-z0-9+/]{42,44}={0,2}$' "$KEY" && [ $(wc -c < "$KEY") -eq 45 ]; then
                        echo " - OK: La clave PRIVADA tiene el formato correcto."
                    else
                        echo " - ALERTA:  La clave PRIVADA tiene un formato INCORRECTO."
                    fi

                    # Verificar formato de la clave pública
                    if grep -qE '^[A-Za-z0-9+/]{42,44}={0,2}$' "$PUB" && [ $(wc -c < "$PUB") -eq 45 ]; then
                        echo " - OK: La clave PÚBLICA tiene el formato correcto."
                        echo ""
                    else
                        echo " - ALERTA: La clave PÚBLICA tiene un formato INCORRECTO."
                        echo ""
                    fi

                    # Verificar que la clave pública corresponde a la privada
                        echo "TOTAL:"
                    if [ "$(cat "$KEY" | wg pubkey)" == "$(cat "$PUB")" ]; then
                        echo " - OK: Las claves son CORRESPONDIENTES (la pública deriva de la privada)."
                    else
                        echo " - ALERTA: Las claves NO CORRESPONDEN entre sí."
                        echo ""
                    fi
                else
                    echo "Ficheros incorrectos para el usuario '${USUARIO}':"
                    [ ! -f "$KEY" ] && echo "- Falta el fichero .key"
                    [ ! -f "$PUB" ] && echo "- Falta el fichero .pub"
                fi
            fi

            read -n1 -r -p "Presione [Enter] para continuar..."
            ;;
        
        3)
            read -p "Ingrese el nombre del usuario a borrar: " USUARIO

            if [ -z "$USUARIO" ]; then
                echo "El nombre de usuario no puede estar vacío."
                read -n1 -r -p "Presione [Enter] para continuar..."
                continue
            fi

            RUTA="/etc/wireguard/clients/${USUARIO}"

            if [ -d "$RUTA" ]; then
                rm -rf "$RUTA"
                echo "Ficheros del usuario '${USUARIO}' borrados correctamente."
            else
                echo "Los ficheros del usuario '${USUARIO}' no existen o ya están borrados."
            fi

            read -n1 -r -p "Presione [Enter] para continuar..."
            ;;

        0|quit|exit)
            echo "Saliendo del script..."
            exit 0
            ;;

        *)
            echo "Opción no válida. Intente nuevamente."
            read -n1 -r -p "Presione [Enter] para continuar..."
            ;;
    esac
done
