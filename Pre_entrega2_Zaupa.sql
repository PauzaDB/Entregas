
DROP DATABASE IF EXISTS retail_project;
CREATE DATABASE retail_project;

-- Conectarse a la nueva base (meta-comando de psql)
\c retail_project
psql -U postgres -h localhost -f retail_project.sql


CREATE TABLE clientes (
    id_cliente  INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre      VARCHAR(100) NOT NULL,
    email       VARCHAR(150) NOT NULL UNIQUE,
    edad        INT NOT NULL,
    ciudad      VARCHAR(80),
    --CHECK : edad válida (mayores de edad)
    CONSTRAINT ck_clientes_edad CHECK (edad BETWEEN 18 AND 120)
);

CREATE TABLE productos (
    id_producto     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre          VARCHAR(120) NOT NULL,
    categoria       VARCHAR(60)  NOT NULL,
    precio_unitario NUMERIC(10,2) NOT NULL,
    stock           INT NOT NULL DEFAULT 0,
    CONSTRAINT ck_productos_precio CHECK (precio_unitario > 0),   -- CHECK 2: el precio debe ser positivo
    CONSTRAINT ck_productos_stock  CHECK (stock >= 0)  -- CHECK 3: el stock no puede ser negativo
);

CREATE TABLE ventas (
    id_venta        INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_cliente      INT NOT NULL,
    id_producto     INT NOT NULL,
    cantidad        INT NOT NULL,
    precio_unitario NUMERIC(10,2) NOT NULL,  -- precio al momento de la venta
    fecha_venta     DATE NOT NULL DEFAULT CURRENT_DATE,
    CONSTRAINT ck_ventas_cantidad CHECK (cantidad > 0),  -- CHECK 4: cantidad vendida mayor a cero
    CONSTRAINT ck_ventas_precio   CHECK (precio_unitario > 0),  -- CHECK 5: precio de venta positivo

    CONSTRAINT fk_ventas_cliente  FOREIGN KEY (id_cliente)  -- Claves foráneas
        REFERENCES clientes (id_cliente)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_ventas_producto FOREIGN KEY (id_producto)
        REFERENCES productos (id_producto)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE INDEX idx_ventas_cliente  ON ventas (id_cliente);
CREATE INDEX idx_ventas_producto ON ventas (id_producto);

-- 4. Carga de datos--

BEGIN;

INSERT INTO clientes (nombre, email, edad, ciudad) VALUES
    ('Lucía Fernández', 'lucia.fernandez@mail.com', 29, 'Buenos Aires'),
    ('Martín Gómez',    'martin.gomez@mail.com',    41, 'Córdoba'),
    ('Sofía Ramírez',   'sofia.ramirez@mail.com',   35, 'Rosario'),
    ('Diego Herrera',   'diego.herrera@mail.com',   23, 'Mendoza'),
    ('Valentina Cruz',  'valentina.cruz@mail.com',  52, 'La Plata');

INSERT INTO productos (nombre, categoria, precio_unitario, stock) VALUES
    ('Notebook 15"',          'Electrónica', 850000.00, 15),
    ('Auriculares Bluetooth', 'Electrónica',  45000.00, 60),
    ('Mouse Inalámbrico',     'Accesorios',   12000.00, 120),
    ('Mochila Urbana',        'Accesorios',   38000.00, 40),
    ('Cafetera Express',      'Hogar',       135000.00, 25);

-- Los ids se generan en orden: clientes 1..5 y productos 1..5
INSERT INTO ventas (id_cliente, id_producto, cantidad, precio_unitario, fecha_venta) VALUES
    (1, 1, 1, 850000.00, '2026-10-02'),
    (2, 2, 2,  45000.00, '2026-10-05'),
    (3, 3, 3,  12000.00, '2026-10-09'),
    (4, 4, 1,  38000.00, '2026-10-14'),
    (5, 5, 1, 135000.00, '2026-10-20'),
    (1, 3, 2,  12000.00, '2026-11-01');

COMMIT;

-- 5. UPDATE y DELETE ---------------------------------------------------

-- Aumentar 10 % el precio de todos los productos de la categoría 'Electrónica'
UPDATE productos
SET    precio_unitario = ROUND(precio_unitario * 1.10, 2)
WHERE  categoria = 'Electrónica';

-- Eliminar una venta específica (la venta con id 6)
DELETE FROM ventas
WHERE  id_venta = 6;

SELECT * FROM productos ORDER BY id_producto;
SELECT * FROM ventas    ORDER BY id_venta;