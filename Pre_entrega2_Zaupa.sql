
DROP DATABASE IF EXISTS retail_project;
CREATE DATABASE retail_project;

CREATE SCHEMA IF NOT EXISTS public;
SET search_path TO public; --Para conectar a la ruta del esquema. 


CREATE TABLE clientes (
    id_cliente  INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY, --Siempre asigna valor de forma automática.
    nombre      VARCHAR(100) NOT NULL,
    email       VARCHAR(150) NOT NULL UNIQUE,
    edad        INT NOT NULL,
    ciudad      VARCHAR(80),
    CONSTRAINT ck_clientes_edad CHECK (edad BETWEEN 18 AND 120) --1er CHECK : edad válida (mayores de edad).
);

CREATE TABLE productos (
    id_producto     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre          VARCHAR(120) NOT NULL,
    categoria       VARCHAR(60)  NOT NULL,
    precio_unitario NUMERIC(10,2) NOT NULL,
    stock           INT NOT NULL DEFAULT 0,
    CONSTRAINT ck_productos_precio CHECK (precio_unitario > 0),   --2do CHECK: el precio debe ser positivo.
    CONSTRAINT ck_productos_stock  CHECK (stock >= 0)  --3er CHECK: el stock no puede ser negativo.
);

CREATE table if not EXISTS ventas (
    id_venta        INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_cliente      INT NOT NULL,
    id_producto     INT NOT NULL,
    cantidad        INT NOT NULL,
    precio_unitario NUMERIC(10,2) NOT NULL,  --precio al momento de la venta.
    fecha_venta     DATE NOT NULL DEFAULT CURRENT_DATE,
    CONSTRAINT ck_ventas_cantidad CHECK (cantidad > 0),  --4to CHECK: cantidad vendida mayor a cero.
    CONSTRAINT ck_ventas_precio   CHECK (precio_unitario > 0),  --5to CHECK: precio de venta positivo.
    CONSTRAINT fk_ventas_cliente  FOREIGN KEY (id_cliente)  --Claves foráneas
        REFERENCES clientes (id_cliente)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_ventas_producto FOREIGN KEY (id_producto) 
        REFERENCES productos (id_producto)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

---Carga de datos en bloque---
-- Los ids se generan en orden: clientes y productos del 1 al 5
BEGIN;

INSERT INTO clientes (nombre, email, edad, ciudad) VALUES
    ('Juancito', 'juan.cito@mail.com', 29, 'Buenos Aires'),
    ('Robertito',    'rober.tito@mail.com',    41, 'Córdoba'),
    ('Jorgito',   'jorgito.alfajor@mail.com',   35, 'Rosario'),
    ('Dieguito',   'diego.maradona@mail.com',   23, 'Mendoza'),
    ('Valentina Cruz',  'valen.cruz@mail.com',  52, 'La Plata');

INSERT INTO productos (nombre, categoria, precio_unitario, stock) VALUES
    ('Notebook 15"',          'Electrónica', 850000.00, 15),
    ('Auriculares Bluetooth', 'Electrónica',  45000.00, 60),
    ('Mouse Inalámbrico',     'Accesorios',   12000.00, 120),
    ('Mochila Urbana',        'Accesorios',   38000.00, 40),
    ('Cafetera Express',      'Hogar',       135000.00, 25);

INSERT INTO ventas (id_cliente, id_producto, cantidad, precio_unitario, fecha_venta) VALUES
    (1, 1, 1, 850000.00, '2026-10-02'),
    (2, 2, 2,  45000.00, '2026-10-05'),
    (3, 3, 3,  12000.00, '2026-10-09'),
    (4, 4, 1,  38000.00, '2026-10-14'),
    (5, 5, 1, 135000.00, '2026-10-20'),
    (1, 3, 2,  12000.00, '2026-11-01');

COMMIT;

---UPDATE y DELETE---

--Aumenta el precio un 10% de todos los productos de la categoría 'Electrónica'
UPDATE productos
SET    precio_unitario = ROUND(precio_unitario * 1.10, 2)
WHERE  categoria = 'Electrónica';

--Se elimina una venta específica (la venta con id 5)
DELETE FROM ventas
WHERE  id_venta = 5;



SELECT * FROM productos ORDER BY id_producto; --Consultas para verificar tablas. 
SELECT * FROM ventas    ORDER BY id_venta;
select * from clientes;