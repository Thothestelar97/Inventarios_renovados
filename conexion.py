import mariadb

def conectar():
    """
    Establece conexión con la base de datos MariaDB.
    Retorna el objeto de conexión o None si falla.
    """
    try:
        conexion = mariadb.connect(
           host="localhost",
           user="root",
           password="19980315",
           port=3306,
           database="poo2"
        )
        return conexion
    except mariadb.Error as e:
        print(f"Error al conectar con MariaDB: {e}")
        return None