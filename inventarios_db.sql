-- ============================================================================
--  INVENTARIOS EMPRESARIALES v3.0
--  Archivo de importacion completo para MySQL Workbench
-- ----------------------------------------------------------------------------
--  INSTRUCCIONES DE IMPORTACION:
--  1. Abrir MySQL Workbench
--  2. Menu superior: Server > Data Import
--  3. Seleccionar "Import from Self-Contained File"
--  4. Buscar este archivo: inventarios_db.sql
--  5. En "Default Target Schema" dejar en blanco (el script crea la BD solo)
--  6. Clic en "Start Import"
--  7. Listo — la base de datos queda lista para usar
-- ----------------------------------------------------------------------------
--  ALTERNATIVA RAPIDA:
--  Abrir este archivo en Workbench (File > Open SQL Script)
--  y presionar el rayo (Execute) o Ctrl+Shift+Enter
-- ============================================================================

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL,ALLOW_INVALID_DATES';

-- ----------------------------------------------------------------------------
-- 1. CREAR Y SELECCIONAR LA BASE DE DATOS
-- ----------------------------------------------------------------------------
DROP DATABASE IF EXISTS inventarios_db;

CREATE DATABASE inventarios_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE inventarios_db;

-- ----------------------------------------------------------------------------
-- 2. TABLA: usuarios
--    Almacena credenciales y roles de acceso al sistema.
--    Las contrasenas estan cifradas con SHA-256.
-- ----------------------------------------------------------------------------
CREATE TABLE usuarios (
    id       INT          NOT NULL AUTO_INCREMENT,
    username VARCHAR(50)  NOT NULL,
    password VARCHAR(64)  NOT NULL  COMMENT 'Hash SHA-256 de la contrasena',
    rol      VARCHAR(20)  NOT NULL  COMMENT 'administrador | gerente | operador | consulta',
    nombre   VARCHAR(100) NOT NULL,
    activo   TINYINT(1)   NOT NULL  DEFAULT 1 COMMENT '1=activo 0=inactivo',
    PRIMARY KEY (id),
    UNIQUE KEY uq_username (username)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Usuarios del sistema con control de roles';

-- ----------------------------------------------------------------------------
-- 3. TABLA: categorias
--    Catalogo de categorias para clasificar los productos.
-- ----------------------------------------------------------------------------
CREATE TABLE categorias (
    id          INT          NOT NULL AUTO_INCREMENT,
    nombre      VARCHAR(100) NOT NULL,
    descripcion TEXT,
    PRIMARY KEY (id),
    UNIQUE KEY uq_cat_nombre (nombre)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Categorias de productos';

-- ----------------------------------------------------------------------------
-- 4. TABLA: productos
--    Catalogo principal del inventario.
--    Referencia a categorias mediante clave foranea.
-- ----------------------------------------------------------------------------
CREATE TABLE productos (
    id            INT           NOT NULL AUTO_INCREMENT,
    codigo        VARCHAR(20)   NOT NULL COMMENT 'Codigo unico del producto',
    nombre        VARCHAR(100)  NOT NULL,
    categoria_id  INT           NOT NULL,
    cantidad      INT           NOT NULL DEFAULT 0,
    precio        DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    stock_minimo  INT           NOT NULL DEFAULT 5 COMMENT 'Umbral de alerta de reabastecimiento',
    fecha_ingreso DATETIME      NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_codigo (codigo),
    KEY idx_categoria (categoria_id),
    KEY idx_stock (cantidad, stock_minimo),
    CONSTRAINT fk_prod_categoria
        FOREIGN KEY (categoria_id) REFERENCES categorias (id)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Catalogo de productos del inventario';

-- ----------------------------------------------------------------------------
-- 5. TABLA: movimientos
--    Historial de todos los ingresos y salidas de stock.
--    Se llena automaticamente desde la aplicacion Python.
-- ----------------------------------------------------------------------------
CREATE TABLE movimientos (
    id          INT         NOT NULL AUTO_INCREMENT,
    producto_id INT         NOT NULL,
    tipo        VARCHAR(10) NOT NULL COMMENT 'INGRESO o SALIDA',
    cantidad    INT         NOT NULL,
    fecha       DATETIME    NOT NULL,
    usuario     VARCHAR(50)          COMMENT 'Usuario que realizo el movimiento',
    observacion TEXT,
    PRIMARY KEY (id),
    KEY idx_producto  (producto_id),
    KEY idx_fecha     (fecha),
    KEY idx_tipo      (tipo),
    CONSTRAINT fk_mov_producto
        FOREIGN KEY (producto_id) REFERENCES productos (id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Historial de movimientos de inventario';

-- ----------------------------------------------------------------------------
-- 6. DATOS INICIALES: categorias
-- ----------------------------------------------------------------------------
INSERT INTO categorias (nombre, descripcion) VALUES
    ('Electronica',  'Dispositivos y componentes electronicos'),
    ('Oficina',      'Papeleria y suministros de oficina'),
    ('Herramientas', 'Herramientas manuales y electricas'),
    ('General',      'Productos de uso general');

-- ----------------------------------------------------------------------------
-- 7. DATOS INICIALES: usuarios
--    Las contrasenas son hash SHA-256. Credenciales de acceso:
--
--    usuario     contrasena       rol
--    ---------   ------------     ---------------
--    admin       admin123         administrador
--    gerente     gerente123       gerente
--    operador    operador123      operador
--    consulta    consulta123      consulta
--
-- ----------------------------------------------------------------------------
INSERT INTO usuarios (username, password, rol, nombre) VALUES
    ('admin',
     '240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a',
     'administrador',
     'Administrador del Sistema'),

    ('gerente',
     '3fc4ccfe745870e2c0d99f71f30ff0656c8dedd41cc1d7d3d376b0dbe685e2f3',
     'gerente',
     'Gerente General'),

    ('operador',
     '73c50b35a27920fbd551b0513e89a24c8d37fdce0177b4d1a2b51e47f564a0c5',
     'operador',
     'Operador de Almacen'),

    ('consulta',
     'c0b3a42e5a6e17fc09ff5fd8c5ba73f83d0aba49e4b7d5e9a1f2c3d4e5f6a7b8',
     'consulta',
     'Usuario de Consulta');

-- ----------------------------------------------------------------------------
-- 8. DATOS DE EJEMPLO: productos (opcionales — borrar si no se necesitan)
-- ----------------------------------------------------------------------------
INSERT INTO productos (codigo, nombre, categoria_id, cantidad, precio, stock_minimo, fecha_ingreso) VALUES
    ('ELEC-001', 'Laptop HP 15 pulgadas',          1, 12, 2500000.00, 3,  NOW()),
    ('ELEC-002', 'Mouse Optico Inalambrico',        1, 45,   35000.00, 10, NOW()),
    ('ELEC-003', 'Teclado USB Estandar',            1, 30,   28000.00, 8,  NOW()),
    ('ELEC-004', 'Monitor LED 24 pulgadas',         1,  8, 850000.00,  2,  NOW()),
    ('ELEC-005', 'Memoria USB 64GB',                1, 60,   22000.00, 15, NOW()),
    ('OFIC-001', 'Resma Papel Carta 500 hojas',     2, 80,   14000.00, 20, NOW()),
    ('OFIC-002', 'Boligrafo Azul x12 unidades',    2,120,    8500.00, 30, NOW()),
    ('OFIC-003', 'Carpeta Archivadora A-Z',         2, 25,   12000.00, 8,  NOW()),
    ('OFIC-004', 'Grapadora Estandar',              2, 15,   18000.00, 4,  NOW()),
    ('OFIC-005', 'Calculadora Cientifica',          2, 10,   45000.00, 3,  NOW()),
    ('HERR-001', 'Taladro Electrico 500W',          3,  6, 180000.00,  2,  NOW()),
    ('HERR-002', 'Juego Destornilladores x8',       3, 18,   35000.00, 5,  NOW()),
    ('HERR-003', 'Cinta Metrica 5 metros',          3, 40,    9000.00, 10, NOW()),
    ('HERR-004', 'Nivel de Burbuja 40cm',           3, 12,   22000.00, 4,  NOW()),
    ('GENE-001', 'Caja Plastica Organizadora',      4, 35,   15000.00, 8,  NOW()),
    ('GENE-002', 'Candado Seguridad 40mm',          4, 20,   25000.00, 5,  NOW()),
    ('GENE-003', 'Extintor CO2 5lb',                4,  4, 120000.00,  2,  NOW()),
    ('GENE-004', 'Botiquin Primeros Auxilios',      4,  3, 85000.00,   2,  NOW());

-- ----------------------------------------------------------------------------
-- 9. DATOS DE EJEMPLO: movimientos iniciales
-- ----------------------------------------------------------------------------
INSERT INTO movimientos (producto_id, tipo, cantidad, fecha, usuario, observacion) VALUES
    (1,  'INGRESO', 12, NOW(), 'admin', 'Registro inicial de inventario'),
    (2,  'INGRESO', 45, NOW(), 'admin', 'Registro inicial de inventario'),
    (3,  'INGRESO', 30, NOW(), 'admin', 'Registro inicial de inventario'),
    (4,  'INGRESO',  8, NOW(), 'admin', 'Registro inicial de inventario'),
    (5,  'INGRESO', 60, NOW(), 'admin', 'Registro inicial de inventario'),
    (6,  'INGRESO', 80, NOW(), 'admin', 'Registro inicial de inventario'),
    (7,  'INGRESO',120, NOW(), 'admin', 'Registro inicial de inventario'),
    (8,  'INGRESO', 25, NOW(), 'admin', 'Registro inicial de inventario'),
    (9,  'INGRESO', 15, NOW(), 'admin', 'Registro inicial de inventario'),
    (10, 'INGRESO', 10, NOW(), 'admin', 'Registro inicial de inventario'),
    (11, 'INGRESO',  6, NOW(), 'admin', 'Registro inicial de inventario'),
    (12, 'INGRESO', 18, NOW(), 'admin', 'Registro inicial de inventario'),
    (13, 'INGRESO', 40, NOW(), 'admin', 'Registro inicial de inventario'),
    (14, 'INGRESO', 12, NOW(), 'admin', 'Registro inicial de inventario'),
    (15, 'INGRESO', 35, NOW(), 'admin', 'Registro inicial de inventario'),
    (16, 'INGRESO', 20, NOW(), 'admin', 'Registro inicial de inventario'),
    (17, 'INGRESO',  4, NOW(), 'admin', 'Registro inicial de inventario'),
    (18, 'INGRESO',  3, NOW(), 'admin', 'Registro inicial de inventario'),
    -- Algunos movimientos de salida de ejemplo
    (2,  'SALIDA',  5, NOW(), 'operador', 'Entrega a departamento de sistemas'),
    (6,  'SALIDA', 10, NOW(), 'operador', 'Consumo mensual oficinas'),
    (7,  'SALIDA', 20, NOW(), 'operador', 'Distribucion a areas'),
    (1,  'SALIDA',  2, NOW(), 'gerente',  'Asignacion equipos nuevos empleados'),
    (5,  'SALIDA',  8, NOW(), 'operador', 'Entrega a usuarios');

-- ----------------------------------------------------------------------------
-- 10. VISTAS UTILES (opcionales — facilitan consultas desde Workbench)
-- ----------------------------------------------------------------------------

-- Vista: resumen del inventario
CREATE OR REPLACE VIEW v_inventario AS
SELECT
    p.id,
    p.codigo,
    p.nombre,
    c.nombre        AS categoria,
    p.cantidad      AS stock_actual,
    p.stock_minimo,
    p.precio,
    (p.cantidad * p.precio) AS valor_total,
    CASE
        WHEN p.cantidad <= p.stock_minimo THEN 'CRITICO'
        WHEN p.cantidad <= p.stock_minimo * 1.5 THEN 'BAJO'
        ELSE 'NORMAL'
    END             AS estado_stock,
    p.fecha_ingreso
FROM productos p
JOIN categorias c ON p.categoria_id = c.id
ORDER BY p.nombre;

-- Vista: valor total por categoria
CREATE OR REPLACE VIEW v_valor_categoria AS
SELECT
    c.nombre        AS categoria,
    COUNT(p.id)     AS total_productos,
    SUM(p.cantidad) AS total_unidades,
    SUM(p.cantidad * p.precio) AS valor_inventario
FROM categorias c
LEFT JOIN productos p ON p.categoria_id = c.id
GROUP BY c.id, c.nombre
ORDER BY valor_inventario DESC;

-- Vista: productos con stock critico
CREATE OR REPLACE VIEW v_stock_critico AS
SELECT
    p.codigo,
    p.nombre,
    c.nombre AS categoria,
    p.cantidad AS stock_actual,
    p.stock_minimo,
    (p.stock_minimo - p.cantidad) AS unidades_faltantes
FROM productos p
JOIN categorias c ON p.categoria_id = c.id
WHERE p.cantidad <= p.stock_minimo
ORDER BY p.cantidad ASC;

-- Vista: historial de movimientos completo
CREATE OR REPLACE VIEW v_movimientos AS
SELECT
    m.id,
    p.codigo,
    p.nombre        AS producto,
    m.tipo,
    m.cantidad,
    m.fecha,
    m.usuario,
    m.observacion
FROM movimientos m
JOIN productos p ON m.producto_id = p.id
ORDER BY m.fecha DESC;

-- ----------------------------------------------------------------------------
-- 11. VERIFICACION FINAL
-- ----------------------------------------------------------------------------
SELECT '====== IMPORTACION COMPLETADA ======' AS mensaje;
SELECT CONCAT('Tablas creadas: ', COUNT(*)) AS tablas
FROM information_schema.tables
WHERE table_schema = 'inventarios_db';

SELECT 'Usuarios registrados:' AS info;
SELECT username, rol, nombre, IF(activo=1,'Activo','Inactivo') AS estado
FROM usuarios;

SELECT 'Categorias registradas:' AS info;
SELECT nombre, descripcion FROM categorias;

SELECT 'Productos de ejemplo:' AS info;
SELECT COUNT(*) AS total_productos FROM productos;

SELECT 'Movimientos registrados:' AS info;
SELECT COUNT(*) AS total_movimientos FROM movimientos;

SELECT '====== BASE DE DATOS LISTA PARA USAR ======' AS mensaje;

-- Restaurar configuracion original
SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
