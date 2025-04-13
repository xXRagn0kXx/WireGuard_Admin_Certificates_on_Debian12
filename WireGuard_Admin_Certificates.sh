#!/bin/bash

while true; do
    clear
    echo ""
    echo "=============================================="
    echo "    MENÚ DE GESTIÓN DE CERTIFICADOS WIREGUARD     "
    echo "=============================================="
    echo "1) Crear par de claves para cliente VPN"
    echo "2) Comprobar cliente"
    echo "3) Borrar par de claves del cliente"
    echo "4) Comprobar par de claves del servidor"
    echo "0|quit|exit) Salir"
    echo "=============================================="
    echo ""
    read -p "Seleccione una opción: " OPCION

    case "$OPCION" in
        1)
            read -p "Ingrese el nombre del usuario VPN: " USUARIO

            if [ -z "$USUARIO" ]; then
                echo "El nombre del cliente no puede estar vacío."
                read -n1 -r -p "Presione [Enter] para continuar..."
                continue
            fi

            RUTA="/etc/wireguard/clients/${USUARIO}"
            mkdir -p "$RUTA"
            wg genkey | tee "${RUTA}/${USUARIO}.key" > /dev/null
            cat "${RUTA}/${USUARIO}.key" | wg pubkey | tee "${RUTA}/${USUARIO}.pub" > /dev/null

            echo "Se los pares de claves para el cliente '${USUARIO}' en la ruta ${RUTA}."
            read -n1 -r -p "Presione [Enter] para continuar..."
            ;;

        2)
            read -p "Ingrese el nombre del cliente a comprobar: " USUARIO
            echo""

            if [ -z "$USUARIO" ]; then
                echo "El nombre del cliente no puede estar vacío."
                read -n1 -r -p "Presione [Enter] para continuar..."
                continue
            fi

            RUTA="/etc/wireguard/clients/${USUARIO}"

            if [ ! -d "$RUTA" ]; then
                echo "No existe ningún dato con ese nombre del cliente '${USUARIO}'."
            else
                KEY="${RUTA}/${USUARIO}.key"
                PUB="${RUTA}/${USUARIO}.pub"

                if [ -f "$KEY" ] && [ -f "$PUB" ]; then
                    echo "El cliente '${USUARIO}' ya tiene ficheros creados."
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
                    echo "Ficheros incorrectos para el cliente '${USUARIO}':"
                    [ ! -f "$KEY" ] && echo "- Falta el fichero .key"
                    [ ! -f "$PUB" ] && echo "- Falta el fichero .pub"
                fi
            fi

            read -n1 -r -p "Presione [Enter] para continuar..."
            ;;

        3)
            read -p "Ingrese el nombre del cliente a borrar: " USUARIO

            if [ -z "$USUARIO" ]; then
                echo "El nombre del cliente no puede estar vacío."
                read -n1 -r -p "Presione [Enter] para continuar..."
                continue
            fi

            RUTA="/etc/wireguard/clients/${USUARIO}"

            if [ -d "$RUTA" ]; then
                rm -rf "$RUTA"
                echo "Ficheros del cliente '${USUARIO}' borrados correctamente."
            else
                echo "Los ficheros del cliente '${USUARIO}' no existen o ya están borrados."
            fi

            read -n1 -r -p "Presione [Enter] para continuar..."
            ;;

        4)
            echo ""
            echo "Comprobando pared de claves del servidor..."
            echo ""

            SERVER_KEY="/etc/wireguard/server.key"
            SERVER_PUB="/etc/wireguard/server.pub"

            if [ -f "$SERVER_KEY" ] && [ -f "$SERVER_PUB" ]; then
                echo "El servidor tiene ficheros de certificados creados."
                echo ""

                # Verificar formato de la clave privada
                if grep -qE '^[A-Za-z0-9+/]{42,44}={0,2}$' "$SERVER_KEY" && [ $(wc -c < "$SERVER_KEY") -eq 45 ]; then
                    echo " - OK: La clave PRIVADA del servidor tiene el formato correcto."
                else
                    echo " - ALERTA: La clave PRIVADA del servidor tiene un formato INCORRECTO."
                fi

                # Verificar formato de la clave pública
                if grep -qE '^[A-Za-z0-9+/]{42,44}={0,2}$' "$SERVER_PUB" && [ $(wc -c < "$SERVER_PUB") -eq 45 ]; then
                    echo " - OK: La clave PÚBLICA del servidor tiene el formato correcto."
                    echo ""
                else
                    echo " - ALERTA: La clave PÚBLICA del servidor tiene un formato INCORRECTO."
                    echo ""
                fi

                # Verificar que la clave pública corresponde a la privada
                echo "TOTAL:"
                if [ "$(cat "$SERVER_KEY" | wg pubkey)" == "$(cat "$SERVER_PUB")" ]; then
                    echo " - OK: Las claves del servidor son CORRESPONDIENTES (la pública deriva de la privada)."
                else
                    echo " - ALERTA: Las claves del servidor NO CORRESPONDEN entre sí."
                    echo ""
                fi
            else
                echo "Ficheros de certificados del servidor incorrectos:"
                [ ! -f "$SERVER_KEY" ] && echo "- Falta el fichero server.key"
                [ ! -f "$SERVER_PUB" ] && echo "- Falta el fichero server.pub"
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
