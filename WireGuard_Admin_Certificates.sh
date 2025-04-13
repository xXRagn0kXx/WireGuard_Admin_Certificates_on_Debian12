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
            CLIENT_KEY="${RUTA}/${USUARIO}.key"
            CLIENT_PUB="${RUTA}/${USUARIO}.pub"

            # Comprobar si el directorio o certificados ya existen
            if [ -d "$RUTA" ]; then
                echo ""
                echo "ADVERTENCIA: El directorio para el cliente '${USUARIO}' ya existe."

                if [ -f "$CLIENT_KEY" ] || [ -f "$CLIENT_PUB" ]; then
                    echo "Se han encontrado certificados existentes:"
                    [ -f "$CLIENT_KEY" ] && echo "- ${CLIENT_KEY}"
                    [ -f "$CLIENT_PUB" ] && echo "- ${CLIENT_PUB}"

                    read -p "¿Desea sobrescribir los certificados existentes? [y/N]: " CONFIRM
                    if [[ ! "$CONFIRM" =~ [yYsS] ]]; then
                        echo "Operación cancelada. No se modificaron los certificados."
                        read -n1 -r -p "Presione [Enter] para continuar..."
                        continue
                    fi
                fi
            fi

            # Crear directorio (o continuar si ya existe)
            mkdir -p "$RUTA"
            echo "Generando pares de claves..."
            wg genkey | tee "${CLIENT_KEY}" > /dev/null
            cat "${CLIENT_KEY}" | wg pubkey | tee "${CLIENT_PUB}" > /dev/null

            echo ""
            echo "Se han creado los certificados para el cliente '${USUARIO}' en:"
            echo "- Clave privada: ${CLIENT_KEY}"
            echo "- Clave pública: ${CLIENT_PUB}"

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
                echo "El nombre del cliente no puede estar vacío."
                read -n1 -r -p "Presione [Enter] para continuar..."
                continue
            fi

            RUTA="/etc/wireguard/clients/${USUARIO}"
            CLIENT_KEY="${RUTA}/${USUARIO}.key"
            CLIENT_PUB="${RUTA}/${USUARIO}.pub"

            # Comprobar si existe el directorio
            if [ ! -d "$RUTA" ]; then
                echo "El directorio del cliente '${USUARIO}' no existe."
                read -n1 -r -p "Presione [Enter] para continuar..."
                continue
            fi

            # Comprobar si existen los ficheros de certificado
            if [ ! -f "$CLIENT_KEY" ] || [ ! -f "$CLIENT_PUB" ]; then
                echo "Advertencia: El directorio del cliente '${USUARIO}' no contiene ficheros de certificado válidos."
                echo "Pero el directorio existe y puede contener otros archivos."
                read -p "¿Desea borrar TODO el contenido del directorio '${USUARIO}'? [y/N]: " CONFIRM
                if [[ "$CONFIRM" =~ [yYsS] ]]; then
                    rm -rf "$RUTA"
                    if [ $? -eq 0 ]; then
                        echo "Directorio del cliente '${USUARIO}' borrado completamente."
                    else
                        echo "Error al borrar el directorio."
                    fi
                else
                    echo "Operación cancelada."
                fi
                read -n1 -r -p "Presione [Enter] para continuar..."
                continue
            fi

            # Si existen los certificados, pedir confirmación para borrar
            read -p "¿Está seguro que desea borrar los certificados y el directorio del cliente '${USUARIO}'? [y/N]: " CONFIRM
            if [[ "$CONFIRM" =~ [yYsS] ]]; then
                rm -rf "$RUTA"
                if [ $? -eq 0 ]; then
                    echo "Ficheros y directorio del cliente '${USUARIO}' borrados correctamente."
                else
                    echo "Error al borrar los ficheros."
                fi
            else
                echo "Operación cancelada."
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
