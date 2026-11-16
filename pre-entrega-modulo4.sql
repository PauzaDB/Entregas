drop database if exists retail_project;
create database retail_project; 

create schema if not exists public;
SET search_path TO public; --Para conectar a la ruta del esquema, soluciona error "no existe relación".


create table clientes (
    id_cliente  INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY, --asigna valor de forma automática.
    nombre      VARCHAR(100) NOT NULL,
    email       VARCHAR(150) NOT NULL UNIQUE,
    edad        INT NOT NULL,
    ciudad      VARCHAR(80),
    CONSTRAINT ck_clientes_edad CHECK (edad BETWEEN 18 AND 120) -- valida la edad para mayor de 18.
);


create table if not exists categorias (
    id_categoria INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre       VARCHAR(60) NOT NULL,
    descripcion  VARCHAR(200),
    CONSTRAINT uq_categorias_nombre UNIQUE (nombre), --limita el tipo de dato y los valores son distintos entre si.
    CONSTRAINT ck_categorias_nombre CHECK (char_length(trim(nombre)) > 0) --elimina espacios en blanco.
    );

create table if not exists productos (
    id_producto     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre          VARCHAR(120) NOT NULL,
    id_categoria    INT NOT NULL,
    precio_unitario NUMERIC(10,2) NOT NULL,
    stock           INT NOT NULL DEFAULT 0,
    CONSTRAINT ck_productos_precio CHECK (precio_unitario > 0),  --4to CHECK: cantidad vendida mayor a cero.
    CONSTRAINT ck_productos_stock  CHECK (stock >= 0), --5to CHECK: precio de venta positivo.
    CONSTRAINT fk_productos_categoria FOREIGN KEY (id_categoria)
        REFERENCES categorias (id_categoria)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

create table ventas (
    id_venta        INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_cliente      INT NOT NULL,
    id_producto     INT NOT NULL,
    cantidad        INT NOT NULL,
    precio_unitario NUMERIC(10,2) NOT NULL,  -- precio al momento de la venta
    fecha_venta     DATE NOT NULL DEFAULT CURRENT_DATE,
    CONSTRAINT ck_ventas_cantidad CHECK (cantidad > 0),
    CONSTRAINT ck_ventas_precio   CHECK (precio_unitario > 0),
    CONSTRAINT fk_ventas_cliente  FOREIGN KEY (id_cliente)
        REFERENCES clientes (id_cliente)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_ventas_producto FOREIGN KEY (id_producto)
        REFERENCES productos (id_producto)
        ON UPDATE CASCADE ON DELETE RESTRICT
);


---Carga de datos--
-- Los ids se generan en orden de 1 a 5 en clientes y productos.

BEGIN; --Se ejecuta primero para iniciar la transacción. 

INSERT INTO clientes (nombre, email, ciudad) values --Se ingresan valores a las tablas. 
    ('Juancito', 'juan.cito@mail.com','Buenos Aires'),
    ('Robertito',  'rober.tito@mail.com', 'Córdoba'),
    ('Jorgito',  'jorgito.alfajor@mail.com', 'Rosario'),
    ('Dieguito', 'diego.maradona@mail.com', 'Mendoza'),
    ('Valentina Cruz', 'valen.cruz@mail.com', 'La Plata');

INSERT INTO categorias (nombre, descripcion) VALUES
    ('Electrónica', 'Dispositivos y equipos electrónicos'),
    ('Accesorios',  'Accesorios y complementos'),
    ('Hogar',       'Artículos para el hogar');

INSERT INTO productos (nombre, id_categoria, precio_unitario, stock) VALUES
    ('Notebook 15',           1, 850000.00, 15),
    ('Auriculares Bluetooth', 1,  45000.00, 60),
    ('Mouse Inalámbrico',     2,  12000.00, 120),
    ('Mochila Urbana',        2,  38000.00, 40),
    ('Cafetera Express',      3, 135000.00, 25);

INSERT INTO ventas (id_cliente, id_producto, cantidad, precio_unitario, fecha_venta) values 
    (1, 1, 1, 850000.00, '2026-10-02'),
    (2, 2, 2,  45000.00, '2026-10-05'),
    (3, 3, 3,  12000.00, '2026-10-09'),
    (4, 4, 1,  38000.00, '2026-10-14'),
    (5, 5, 1, 135000.00, '2026-10-20'),
    (1, 3, 2,  12000.00, '2026-11-01');

COMMIT; --Realiza los cambios de forma permanente. 

ROLLBACK; --Deshace los cambios realizados en la transacción, si no se ejecuto el Commit.


SELECT * FROM productos; --Consultas para verificar datos en tablas.
SELECT * FROM ventas;
SELECT * FROM clientes;
SELECT * FROM categorias;

--1 Rentabilidad por categoría.
SELECT c.nombre AS categoria, --se le añade el alias categoria.
       SUM(v.cantidad) AS unidades_vendidas,
       SUM(v.cantidad * v.precio_unitario) AS ingreso_total,
FROM ventas v
JOIN productos  p ON p.id_producto  = v.id_producto 
JOIN categorias c ON c.id_categoria = p.id_categoria
GROUP BY c.id_categoria, c.nombre --Se agrupan filas por categoría y nombre.
having SUM(v.cantidad * v.precio_unitario) > 100000 --Umbral definido en 100000 de ingreso total porque equivale
-- al precio de un producto de gama media del catálogo, los productos menores a esos montos generan pocos ingresos.
ORDER  BY ingreso_total DESC;

--2 clientes sin compras
SELECT c.id_cliente,
       c.nombre,
       c.email,
       COALESCE(c.ciudad, 'Sin ciudad') AS ciudad, --Reemplaza los Nulls por datos legiles ('sin ciudad').
       COALESCE(SUM(v.cantidad), 0) AS unidades_compradas,
       COALESCE(MAX(v.fecha_venta)::TEXT, 'Sin compras') AS ultima_compra --Lo genera en la columna temporal "ultima_compra"
FROM clientes c
LEFT JOIN ventas v ON v.id_cliente = c.id_cliente --Los clientes sin coicidencia en ventas son Null.
GROUP BY c.id_cliente, c.nombre, c.email, c.ciudad --Agrupa los clientes con sus datos.
HAVING COUNT(v.id_venta) = 0 --Cuenta los grupos donde no hay ventas asociadas.
ORDER BY c.nombre; --Lo ordena por nombre. 

--3 Top de compras por cliente.
SELECT cl.nombre AS cliente
	(SELECT p2.nombre FROM   ventas v2 JOIN   productos p2 ON p2.id_producto = v2.id_producto
	WHERE  v2.id_cliente = cl.id_cliente --ventas que evalua el cliente alias v2.
	GROUP  BY p2.id_producto, p2.nombre 
	ORDER  BY COUNT(*) DESC, p2.nombre
	LIMIT  1) AS producto_mas_comprado,
       MAX(v.fecha_venta) AS ultima_transaccion
FROM   clientes cl
JOIN   ventas    v ON v.id_cliente  = cl.id_cliente --Empareja filas 
JOIN   productos p ON p.id_producto = v.id_producto
GROUP  BY cl.id_cliente, cl.nombre
ORDER  BY cl.nombre; --Se agrupa las ventas del cliente por producto.