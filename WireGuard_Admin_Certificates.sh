#!/bin/bash

while true; do
    clear
    echo ""
    echo "=============================================="
    echo "    MENU ADMINISTRACION CERTIFICADOS WIREGUARD     "
    echo "=============================================="
    echo "1) Crear par de claves para cliente VPN"
    echo "2) Comprobar ficheros de cliente VPN"
    echo "3) Borrar par de claves del cliente VPN"
    echo "4) Comprobar par de claves del servidor VPN"
    echo "5) Crear par de claves del servidor VPN"
    echo "0|quit|exit) Salir"
    echo "=============================================="
    echo ""
    read -p "Elige una opcion: " OPCION

    case "$OPCION" in
        1)
            echo ""
            echo "Opcion seleccionada crear ficheros de cliente VPN"
            echo "Si no tiene nombre poner [user] "
            read -p "Ingrese el nombre del cliente VPN: " USUARIO
            

            if [ -z "$USUARIO" ]; then
                echo "El nombre del cliente no puede estar vacío."
                read -n1 -r -p "Presione [Enter] para continuar..."
                continue
            fi

            RUTA="/etc/wireguard/clients/${USUARIO}"
            echo " Creando la ruta para el cliente ${USUARIO} " 
            mkdir -p "$RUTA"
            echo " Generando pares de claves... "
            wg genkey | tee "${RUTA}/${USUARIO}.key" > /dev/null
            cat "${RUTA}/${USUARIO}.key" | wg pubkey | tee "${RUTA}/${USUARIO}.pub" > /dev/null

            echo "Se crean los pares de claves para el cliente '${USUARIO}' en la ruta ${RUTA}."
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
                CLIENT_KEY="${RUTA}/${USUARIO}.key"
                CLIENT_PUB="${RUTA}/${USUARIO}.pub"

                if [ -f "$CLIENT_KEY" ] && [ -f "$CLIENT_PUB" ]; then
                    echo "El cliente '${USUARIO}' ya tiene ficheros creados."
                    echo ""

                    # Verificar formato de la clave privada
                    if grep -qE '^[A-Za-z0-9+/]{42,44}={0,2}$' "$CLIENT_KEY" && [ $(wc -c < "$CLIENT_KEY") -eq 45 ]; then
                        echo " - OK: La clave PRIVADA tiene el formato correcto."
                    else
                        echo " - WARNING:  La clave PRIVADA tiene un formato INCORRECTO."
                    fi

                    # Verificar formato de la clave publica
                    if grep -qE '^[A-Za-z0-9+/]{42,44}={0,2}$' "$CLIENT_PUB" && [ $(wc -c < "$CLIENT_PUB") -eq 45 ]; then
                        echo " - OK: La clave PUBLICA tiene el formato correcto."
                        echo ""
                    else
                        echo " - WARNING: La clave PUBLICA tiene un formato INCORRECTO."
                        echo ""
                    fi

                    # Verificar que la clave publica corresponde a la privada
                        echo "TOTAL:"
                    if [ "$(cat "$CLIENT_KEY" | wg pubkey)" == "$(cat "$CLIENT_PUB")" ]; then
                        echo " - OK: Las claves son CORRESPONDIENTES (la publica corresponde con la privada)."
                    else
                        echo " - WARNING: Las claves NO SE CORRESPONDEN."
                        echo ""
                    fi
                else
                    echo "Ficheros incorrectos para el cliente '${USUARIO}':"
                    [ ! -f "$CLIENT_KEY" ] && echo "- Falta el fichero .key"
                    [ ! -f "$CLIENT_PUB" ] && echo "- Falta el fichero .pub"
                fi
            fi

            read -n1 -r -p "Presione [Enter] para continuar..."
            ;;

        3)
            read -p "Ingrese el nombre del cliente a borrar: " USUARIO

            if [ -z "$USUARIO" ]; then
                echo "El nombre del cliente no puede estar vacio."
                read -n1 -r -p "Presione [Enter] para continuar..."
                continue
            fi

            RUTA="/etc/wireguard/clients/${USUARIO}"

            if [ -d "$RUTA" ]; then
                rm -rf "$RUTA"
                echo "Ficheros del cliente '${USUARIO}' borrados correctamente."
            else
                echo "Los ficheros del cliente '${USUARIO}' no existen o ya estan borrados."
            fi

            read -n1 -r -p "Presione [Enter] para continuar..."
            ;;

        4)
            echo ""
            echo "Comprobando par de claves del servidor..."
            echo ""

            # Preguntar por los nombres de los ficheros con valores por defecto
            read -p "Escribe el nombre del fichero .key (sin la extensión) alojado en la ruta /etc/wireguard/ [por defecto: server.key]: " KEY_NAME
            read -p "Escribe el nombre del fichero .pub (sin la extensión) alojado en la ruta /etc/wireguard/ [por defecto: server.pub]: " PUB_NAME

            # Establecer valores por defecto si el usuario no introduce nada
            KEY_NAME=${KEY_NAME:-server}
            PUB_NAME=${PUB_NAME:-server}

            SERVER_KEY="/etc/wireguard/${KEY_NAME}.key"
            SERVER_PUB="/etc/wireguard/${PUB_NAME}.pub"

            if [ -f "$SERVER_KEY" ] && [ -f "$SERVER_PUB" ]; then
                echo ""
                echo "Los ficheros de claves del servidor existen:"
                echo "- Clave privada: $SERVER_KEY"
                echo "- Clave pública: $SERVER_PUB"
                echo ""

                # Verificar formato de la clave privada
                if grep -qE '^[A-Za-z0-9+/]{42,44}={0,2}$' "$SERVER_KEY" && [ $(wc -c < "$SERVER_KEY") -eq 45 ]; then
                    echo " - OK: La clave PRIVADA tiene el formato correcto."
                else
                    echo " - ALERTA: La clave PRIVADA tiene un formato INCORRECTO."
                fi

                # Verificar formato de la clave publica
                if grep -qE '^[A-Za-z0-9+/]{42,44}={0,2}$' "$SERVER_PUB" && [ $(wc -c < "$SERVER_PUB") -eq 45 ]; then
                    echo " - OK: La clave PUBLICA tiene el formato correcto."
                    echo ""
                else
                    echo " - ALERTA: La clave PUBLICA tiene un formato INCORRECTO."
                    echo ""
                fi

                # Verificar que la clave publica corresponde a la privada
                echo "TOTAL:"
                if [ "$(cat "$SERVER_KEY" | wg pubkey)" == "$(cat "$SERVER_PUB")" ]; then
                    echo " - OK: Las claves son CORRESPONDIENTES (la publica deriva de la privada)."
                else
                    echo " - ALERTA: Las claves NO CORRESPONDEN entre sí."
                    echo ""
                fi
            else
                echo ""
                echo "Ficheros de certificados del servidor no encontrados:"
                [ ! -f "$SERVER_KEY" ] && echo "- No existe: $SERVER_KEY"
                [ ! -f "$SERVER_PUB" ] && echo "- No existe: $SERVER_PUB"
                echo "Por favor, verifica los nombres introducidos."
            fi

            read -n1 -r -p "Presione [Enter] para continuar..."
          ;;
        5)
            echo ""
            echo "Creando par de claves del servidor..."
            echo ""

            # Preguntar por los nombres de los ficheros (con valores por defecto)
            read -p "Escribe el nombre para el fichero .key (sin extension) [por defecto: server]: " KEY_NAME
            read -p "Escribe el nombre para el fichero .pub (sin extension) [por defecto: server]: " PUB_NAME

            # Establecer valores por defecto si el usuario no introduce nada
            KEY_NAME=${KEY_NAME:-server}
            PUB_NAME=${PUB_NAME:-server}

            SERVER_KEY="/etc/wireguard/${KEY_NAME}.key"
            SERVER_PUB="/etc/wireguard/${PUB_NAME}.pub"

            # Comprobar si ya existen los ficheros con formato correcto
            if [ -f "$SERVER_KEY" ] && [ -f "$SERVER_PUB" ]; then
                echo "Los ficheros de claves del servidor ya existen:"
                echo "- Clave privada: $SERVER_KEY"
                echo "- Clave publica: $SERVER_PUB"

                # Verificar si tienen el formato correcto
                KEY_VALID=$(grep -qE '^[A-Za-z0-9+/]{42,44}={0,2}$' "$SERVER_KEY" && [ $(wc -c < "$SERVER_KEY") -eq 45 ] && echo "true")
                PUB_VALID=$(grep -qE '^[A-Za-z0-9+/]{42,44}={0,2}$' "$SERVER_PUB" && [ $(wc -c < "$SERVER_PUB") -eq 45 ] && echo "true")

                if [ "$KEY_VALID" = "true" ] && [ "$PUB_VALID" = "true" ]; then
                    echo " - Las claves existentes tienen el formato correcto."
                    echo " - No se realizara ninguna accion para evitar sobrescribirlas."
                else
                    echo " - ALERTA: Las claves existentes tienen formato incorrecto."
                    read -p "¿Desea sobrescribirlas? [y/N]: " CONFIRM
                    if [[ "$CONFIRM" =~ [yY] ]]; then
                        # Continuar con la creación
                        echo " - Sobrescribiendo claves existentes..."
                    else
                        echo " - Operacion cancelada."
                        read -n1 -r -p "Presione [Enter] para continuar..."
                        continue
                    fi
                fi
            else
                # Crear directorio si no existe
                mkdir -p "/etc/wireguard/"
                echo "Creando nuevas claves para el servidor en:"
                echo "- Clave privada: $SERVER_KEY"
                echo "- Clave publica: $SERVER_PUB"

                # Generar claves
                wg genkey | tee "$SERVER_KEY" > /dev/null
                cat "$SERVER_KEY" | wg pubkey | tee "$SERVER_PUB" > /dev/null

                # Verificar que se crearon correctamente
                if [ -f "$SERVER_KEY" ] && [ -f "$SERVER_PUB" ]; then
                    echo " - Las claves del servidor se han creado correctamente."

                    # Verificar formato
                    if grep -qE '^[A-Za-z0-9+/]{42,44}={0,2}$' "$SERVER_KEY" && [ $(wc -c < "$SERVER_KEY") -eq 45 ]; then
                        echo " - OK: La clave PRIVADA del servidor tiene el formato correcto."
                    else
                        echo " - ALERTA: La clave PRIVADA del servidor tiene un formato INCORRECTO."
                    fi

                    if grep -qE '^[A-Za-z0-9+/]{42,44}={0,2}$' "$SERVER_PUB" && [ $(wc -c < "$SERVER_PUB") -eq 45 ]; then
                        echo " - OK: La clave PUBLICA del servidor tiene el formato correcto."
                    else
                        echo " - ALERTA: La clave PUBLICA del servidor tiene un formato INCORRECTO."
                    fi

                    # Verificar correspondencia
                    if [ "$(cat "$SERVER_KEY" | wg pubkey)" == "$(cat "$SERVER_PUB")" ]; then
                        echo " - OK: Las claves son CORRESPONDIENTES."
                    else
                        echo " - ALERTA: Las claves NO CORRESPONDEN entre sí."
                    fi
                else
                    echo " - ERROR: No se pudieron crear las claves del servidor."
                fi
            fi

            read -n1 -r -p "Presione [Enter] para continuar..."
        ;;

        0|quit|exit)
            echo "Saliendo del script..."
            exit 0
            ;;

        *)
            echo "Opcion no valida. Intente nuevamente."
            read -n1 -r -p "Presione [Enter] para continuar..."
            ;;
    esac
done
