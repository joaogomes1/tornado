DROP DATABASE tornado;
CREATE DATABASE tornado;
USE tornado;


/* USUARIO */

CREATE TABLE usuario (
	id_usuario		INT(11) PRIMARY KEY AUTO_INCREMENT,
	usu_nome 		VARCHAR(100) UNIQUE NOT NULL,
	usu_cpf			CHAR(11),
	usu_celular		CHAR(11) UNIQUE NOT NULL, /* somente números */
	usu_email 		VARCHAR(50) UNIQUE NOT NULL,
	usu_senha 		VARCHAR(10) NOT NULL,
		CONSTRAINT ck_password
		-- CHECK (LENGTH(senha) BETWEEN 8 AND 10)
		CHECK (CHARACTER_LENGTH(usu_senha) >= 8
		AND CHARACTER_LENGTH(usu_senha) <= 10)	/* allows more than 10 characters (!),
												but truncates data */
	/* usu_is_admin	BOOLEAN	DEFAULT 0 */
);

INSERT INTO usuario
(usu_nome, usu_cpf, usu_celular, usu_email, usu_senha)
VALUES
('ana beatriz',			'12345678901',			'19981883001',	'ana@email.com',	'81883001'),
('roberto cerqueira',	'12345678902',			'19981823002',	'beto@email.com',	'81823002'),
('cesar coelho',		'12345678903',			'19981823003',	'cesar@email.com',	'81823003'),
('dênis gonçalves',		'12345678904',			'19981823004',	'denis@email.com',	'81823004'),
('erik silva',			'12345678905',			'19981883005',	'erik@email.com',	'81823005'),
('fabio santos',		'12345678906',			'19981883006',	'fabio@email.com',	'81823006'),
('joão gomes',			'12345678907',			'19981883007',	'joao@email.com',	'81823007');

/* listar usuários */

DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `listarUsuarios`()
BEGIN
	SELECT *
	FROM usuario;
END$$
DELIMITER ;


/* PESSOA JURÍDICA */
/* CREATE TABLE pessoa_juridica (
	id_pessoa_juridica	INT PRIMARY KEY AUTO_INCREMENT,
	id_usuario			INT NOT NULL,
		CONSTRAINT fk_id_usuario
		FOREIGN KEY (id_usuario)
		REFERENCES usuario(id_usuario),
	pess_jur_cnpj		CHAR(14) UNIQUE NOT NULL
); */


/* ADMIN */

/* CREATE TABLE admin (
	id_admin	INT PRIMARY KEY AUTO_INCREMENT,
	id_usuario	INT UNIQUE NOT NULL,
		CONSTRAINT fk_id_usuario_2
		FOREIGN KEY (id_usuario)
		REFERENCES usuario(id_usuario)
);

INSERT INTO admin
(id_usuario)
VALUES
(7); */

/* listar Administradores */

DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `listarAdministradores`()
BEGIN
	SELECT id_admin, usu_nome, usu_celular, usu_email
	FROM admin
	INNER JOIN usuario
	ON admin.id_usuario = usuario.id_usuario;
END$$
DELIMITER ;


/* ESTABELECIMENTO */

CREATE TABLE estabelecimento (
	id_estabelecimento	INT(11) PRIMARY KEY AUTO_INCREMENT,
	est_nome 			VARCHAR(50)	NOT NULL,
	est_endereco		VARCHAR(100) NOT NULL, # dois proprietários podem ter seus estabelecimentos em um mesmo endereço.
	id_usuario			INT(11) NOT NULL, /* o proprietário do estabelecimento */
		CONSTRAINT fk_id_usuario_3
		FOREIGN KEY (id_usuario)
		REFERENCES usuario(id_usuario),
	est_pix_codigo		VARCHAR(100) NOT NULL,
	est_url				VARCHAR(2048) UNIQUE
);

INSERT INTO estabelecimento
(est_nome, est_endereco, id_usuario)
VALUES
('bob lanches', 'rua um, bairro dois, n. 95, americana, sp', 1),
('jota lanches', 'rua três, bairro quatro, n.108, sumaré, sp', 2),
('fabão lanches', 'rua dois, bairro três, n. 99, sumaré, sp', 1),
('porquinho lanches', 'rua um, bairro dois, n. 35, americana, sp', 2),
('jagunço lanches', 'rua um, bairro dois, n. 95, americana, sp', 1);

/* inserir estabelecimento */

DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `inserirEstabelecimento`(
	IN arg_est_nome		VARCHAR(50),
	IN arg_est_endereco	VARCHAR(100),
	IN arg_id_usuario	INT
)
BEGIN
	INSERT INTO estabelecimento
	(est_nome, est_endereco, id_usuario)
	VALUES
	(arg_est_nome, arg_est_endereco, arg_id_usuario);

	SELECT *
	FROM estabelecimento
	ORDER BY id_estabelecimento DESC;
END$$
DELIMITER ;

/* pesquisar estabelecimento por nome */

DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `pesquisarEstabelecimentoPorNome`(IN arg_est_nome VARCHAR(50))
BEGIN
	IF (arg_est_nome = '') THEN
		SELECT 'informe o nome.' AS resultado;
	ELSE
		SELECT est_nome, est_endereco, usu_nome
		FROM estabelecimento
		INNER JOIN usuario
		ON estabelecimento.id_usuario = usuario.id_usuario
		WHERE est_nome LIKE CONCAT('%', arg_est_nome, '%');
	END IF;
END$$
DELIMITER ;

/* listar estabelecimentos */

DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `listarEstabelecimentos`()
BEGIN
	SELECT id_estabelecimento, est_nome, est_endereco, usu_nome, usu_celular
	FROM estabelecimento
	INNER JOIN usuario
	ON estabelecimento.id_usuario = usuario.id_usuario;
END$$
DELIMITER ;

/* iniciar sessão */

DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `iniciarSessao`(
	IN arg_usu_email	VARCHAR(50),
    IN arg_usu_senha	VARCHAR(10)
)
BEGIN
    DECLARE v_id_usuario INT;
	DECLARE v_usu_nome VARCHAR(100);
	DECLARE v_id_estabelecimento INT;
	
    SET v_id_usuario = 0;
	SET v_usu_nome = NULL;
	SET v_id_estabelecimento = 0;

	IF (arg_usu_email = '' OR arg_usu_senha = '') THEN
		SELECT 'informe os valores.' AS resultado;
	ELSE
		SELECT id_usuario
		INTO v_id_usuario
		FROM usuario
		WHERE usu_email = arg_usu_email
		AND usu_senha = arg_usu_senha;

		IF (v_id_usuario = 0 ) THEN
			SELECT 'credenciais inválidas.' AS resultado;
		ELSE
			/* greetings */
			SELECT usu_nome
			INTO v_usu_nome
			FROM usuario
			WHERE id_usuario = v_id_usuario;

			SELECT CONCAT('olá, ', SUBSTRING_INDEX(v_usu_nome, ' ', 1), '!') AS resultado;

			/* checa se o usuário é proprietário de algum estabelecimento. */
			SELECT id_estabelecimento
			INTO v_id_estabelecimento /* altera o valor 0, caso o proprietário possua estabelecimentos. */
			FROM estabelecimento
			WHERE id_usuario = v_id_usuario
			LIMIT 1;

			IF (v_id_estabelecimento = 0) THEN
				SELECT 'usuário logado como cliente.' AS resultado;
			ELSE
				SELECT id_estabelecimento, est_nome, est_endereco
				FROM estabelecimento
				WHERE id_usuario = v_id_usuario;

				SELECT 'usuário logado como proprietário.' AS resultado;
			END IF;	
		END IF;
	END IF;
END$$
DELIMITER ;


/* CATEGORIA */

CREATE TABLE categoria (
	id_categoria	INT PRIMARY KEY AUTO_INCREMENT,
    cat_nome		VARCHAR(50) UNIQUE NOT NULL,
	cat_ativa		BOOLEAN NOT NULL DEFAULT 1
);

INSERT INTO categoria
(cat_nome)
VALUES
('lanche'),
('pizza'),
('porção'),
('bebida'),
('sobremesa');

/* inserir categoria */

DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `inserirCategoria`(IN arg_cat_nome VARCHAR(50))
BEGIN
	INSERT INTO categoria
    (cat_nome)
    VALUE
    (arg_cat_nome);
    
    SELECT *
    FROM categoria
    ORDER BY id_categoria DESC;
END$$
DELIMITER ;

/* inativar categoria */

DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `inativarCategoria`(IN arg_id_categoria INT)
BEGIN
	/* e se o argumento for um id inexistente? */
	/* ignora se a categoria já está inativa */
	UPDATE categoria
	SET cat_ativa = 0
	WHERE id_categoria = arg_id_categoria;
    
    SELECT *
    FROM categoria
    ORDER BY cat_ativa;
END$$
DELIMITER ;

/* ativar categoria */

DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `ativarCategoria`(IN arg_id_categoria INT)
BEGIN
	/* ignora se a categoria já está ativa */
	/* e se o argumento for um id inexistente? */
	UPDATE categoria
	SET cat_ativa = 1
	WHERE id_categoria = arg_id_categoria;
    
    SELECT *
    FROM categoria;
END$$
DELIMITER ;

/* listar categorias ativas */

DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `listarCategoriasAtivas`()
BEGIN
	SELECT *
    FROM categoria
    WHERE cat_ativa = 1;
END$$
DELIMITER ;


/* PRODUTO */

/* criar constraints do tipo 'check' */
CREATE TABLE produto (
	id_produto			INT PRIMARY KEY AUTO_INCREMENT,
    prod_nome			VARCHAR(50) NOT NULL,
    prod_descricao		VARCHAR(200),
    prod_valor			DECIMAL(8, 2) NOT NULL,
    id_categoria		INT NOT NULL,
		CONSTRAINT fk_id_categoria
		FOREIGN KEY (id_categoria)
		REFERENCES categoria(id_categoria),
	id_estabelecimento 	INT NOT NULL,
		CONSTRAINT fk_id_estabelecimento
		FOREIGN KEY (id_estabelecimento)
		REFERENCES estabelecimento(id_estabelecimento),
	prod_ativo			BOOLEAN NOT NULL DEFAULT 1
);

/* evita duplicação de lanches no mesmo estabelecimento */
ALTER TABLE produto
ADD CONSTRAINT unique_lanche_estabelecimento UNIQUE (prod_nome, id_estabelecimento);

INSERT INTO produto
(prod_nome, prod_descricao, prod_valor, id_categoria, id_estabelecimento)
VALUES
('x-bacon', 'vai tomate', 14.99, 1, 1),
('x-bacon', 'suculento', 13.99, 1, 2),
('x-bacon', 'suculento', 13.99, 1, 3),
('x-salada', 'vai pickles', 11.99, 1, 1),
('refrigerante de cola', 'trincando', 6.99, 2, 1),
('refrigerante de limão', 'super gelado', 6.99, 2, 2),
('mousse de chocolate', 'delicioso e fit', 9.99, 3, 1),
('bombom de chocolate', 'delicioso', 2.99, 3, 1);

/* inserir produto */

DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `inserirProduto`(
	IN arg_prod_nome			VARCHAR(50),
	IN arg_prod_descricao		VARCHAR(200),
	IN arg_prod_valor			DECIMAL(8, 2),
	IN arg_id_categoria			INT,
	IN arg_id_estabelecimento	INT
)
BEGIN
	INSERT INTO produto
	(prod_nome, prod_descricao, prod_valor, id_categoria, id_estabelecimento)
    VALUES
    (arg_prod_nome, arg_prod_descricao, arg_prod_valor, arg_id_categoria, arg_id_estabelecimento);
    
    SELECT *
    FROM produto
    ORDER BY id_produto DESC;
END$$
DELIMITER ;

/* listar produtos de um estabelecimento */

DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `listarProdutosDeUmEstabelecimento`(IN arg_id_estabelecimento INT)
BEGIN
	SELECT est_nome, prod_nome, prod_descricao, prod_valor, prod_ativo
	FROM estabelecimento
	INNER JOIN produto
	ON produto.id_estabelecimento = estabelecimento.id_estabelecimento
	WHERE estabelecimento.id_estabelecimento = arg_id_estabelecimento
    
    ORDER BY id_categoria, prod_nome;
END$$
DELIMITER ;

/* selecionar um produto */

DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `selecionarUmProduto`(IN arg_id_produto INT)
BEGIN
	SELECT *
	FROM produto
	WHERE id_produto = arg_id_produto;
END$$
DELIMITER ;

/* retornar id produto ???????????????????????????????????? */

DELIMITER $$
CREATE DEFINER=`root`@`localhost` FUNCTION `retornarIdProduto`(arg_id_estabelecimento INT, arg_id_produto INT) RETURNS INT
BEGIN
    RETURN (
		SELECT id_produto
		FROM produto
		WHERE id_estabelecimento = arg_id_estabelecimento
		AND id_produto = arg_id_produto
	);
END$$
DELIMITER ;

/* inativar produto */

DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `inativarProduto`(
	IN arg_id_estabelecimento INT,
	IN arg_id_produto INT
)
BEGIN
	DECLARE v_id_produto INT;
	
	SET v_id_produto = retornarIdProduto(arg_id_estabelecimento, arg_id_produto);

	IF (ISNULL(v_id_produto)) THEN
		SELECT 'produto não encontrado.' AS resultado;
	ELSE
		UPDATE produto
		SET prod_ativo = 0
		WHERE id_produto = arg_id_produto;

		SELECT 'produto inativado com sucesso.' AS resultado;

		CALL selecionarUmProduto(arg_id_produto);
	END IF;
END$$
DELIMITER ;

/* ativar produto */

DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `ativarProduto`(
	IN arg_id_estabelecimento INT,
	IN arg_id_produto INT
)
BEGIN
	DECLARE v_id_produto INT;
	
	SET v_id_produto = retornarIdProduto(arg_id_estabelecimento, arg_id_produto);

	IF (ISNULL(v_id_produto)) THEN
		SELECT 'produto não encontrado.' AS resultado;
	ELSE
		UPDATE produto
		SET prod_ativo = 1
		WHERE id_produto = arg_id_produto;

		SELECT 'produto ativado com sucesso.' AS resultado;

		CALL selecionarUmProduto(arg_id_produto);
	END IF;
END$$
DELIMITER ;


/* STATUS DO PEDIDO */

CREATE TABLE status_pedido (
	id_status_pedido	INT PRIMARY KEY AUTO_INCREMENT,
    stat_ped_descricao	VARCHAR(100) UNIQUE NOT NULL
);

INSERT INTO status_pedido
(stat_ped_descricao)
VALUES
('pedido registrado'),
/* ('aguardando comprovante de pagamento'), pix */
('aguardando pagamento'), /* pix */
('pagamento confirmado'),
('em preparo'),
('pronto'),
('entregue ao cliente'),
('cancelado');

/* listar tipos de status */

DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `listarTiposDeStatus`()
BEGIN
	SELECT *
	FROM status_pedido
	ORDER BY id_status_pedido;
END$$
DELIMITER ;


/* AVALIACAO  */

CREATE TABLE avaliacao (
	id_avaliacao	INT PRIMARY KEY AUTO_INCREMENT,
	aval_descricao	VARCHAR(20) UNIQUE NOT NULL
);

INSERT INTO avaliacao
(aval_descricao)
VALUES
-- ('não avaliado'),
('ótimo'),
('pode melhorar'),
('não gostei');

/* listar avaliações */

DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `listarTiposDeAvaliacao`()
BEGIN
	SELECT *
	FROM avaliacao
	ORDER BY id_avaliacao;
END$$
DELIMITER ;


/* TIPO DE PAGAMENTO */

CREATE TABLE pagamento (
	id_pagamento	INT PRIMARY KEY AUTO_INCREMENT,
    pag_descricao	VARCHAR(50) NOT NULL
);

INSERT INTO pagamento
(pag_descricao)
VALUES
('dinheiro'),
('cartão de débito (maquininha)'),
('cartão de crédito (maquininha)'),
('pix');

/* listar tipos de pagamento */

DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `listarTiposDePagamento`()
BEGIN
	SELECT *
	FROM pagamento
	ORDER BY id_pagamento;
END$$
DELIMITER ;


/* PEDIDO */

CREATE TABLE pedido (
	id_pedido			INT PRIMARY KEY AUTO_INCREMENT,
	ped_data_hora		DATETIME DEFAULT CURRENT_TIMESTAMP(),
    id_estabelecimento	INT NOT NULL,
		CONSTRAINT fk_id_estabelecimento_2
		FOREIGN KEY (id_estabelecimento)
		REFERENCES estabelecimento(id_estabelecimento),
    id_usuario 			INT NOT NULL,
		CONSTRAINT fk_id_usuario_4
		FOREIGN KEY (id_usuario)
		REFERENCES usuario(id_usuario),
	id_pagamento		INT NOT NULL,
		CONSTRAINT fk_id_pagamento
		FOREIGN KEY (id_pagamento)
		REFERENCES pagamento(id_pagamento),
	id_status_pedido	INT NOT NULL,
		CONSTRAINT fk_id_status_pedido
		FOREIGN KEY (id_status_pedido)
		REFERENCES status_pedido(id_status_pedido),
	id_avaliacao		INT,
		CONSTRAINT fk_id_avaliacao
		FOREIGN KEY (id_avaliacao)
		REFERENCES avaliacao(id_avaliacao)
);

/* não deve ser executado fora de procedure, pois erroneamente permitirá status inválidos para pedidos com pagamento em dinheiro / cartões. */
INSERT INTO pedido
(id_estabelecimento, id_usuario, id_pagamento, id_status_pedido)
VALUES
(2, 1, 2, 3),
(1, 3, 2, 3),
(2, 2, 1, 3);

/* listar pedidos de estabelecimentos */

DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `listarPedidosDeEstabelecimentos`()
BEGIN
	SELECT est_nome, id_pedido, usu_nome, usu_celular,	pag_descricao, stat_ped_descricao, aval_descricao
    FROM estabelecimento
    INNER JOIN pedido
    ON pedido.id_estabelecimento = estabelecimento.id_estabelecimento
    
    INNER JOIN usuario
    ON pedido.id_usuario = usuario.id_usuario
    
    INNER JOIN pagamento
    ON pagamento.id_pagamento = pedido.id_pagamento
    
    INNER JOIN status_pedido
    ON pedido.id_status_pedido = status_pedido.id_status_pedido
    
    LEFT JOIN avaliacao
    ON pedido.id_avaliacao = avaliacao.id_avaliacao

	ORDER BY est_nome, id_pedido;
END$$
DELIMITER ;

/* Inserir pedido */

DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `inserirPedido`(
	IN arg_id_estabelecimento	INT,
    IN arg_id_usuario			INT,
    IN arg_id_pagamento			INT
)
BEGIN
	DECLARE v_id_pagamento INT;
	DECLARE v_id_status_pedido INT;

	SET v_id_pagamento = 0;
	SET v_id_status_pedido = 0;

	SELECT id_pagamento
	INTO v_id_pagamento
	FROM pagamento
	WHERE id_pagamento = arg_id_pagamento;

	/* IF (v_id_pagamento = 0) THEN
		SELECT 'a modalidade de pagamento é inválida.' AS resultado;
	ELSE */
		IF (v_id_pagamento = (SELECT id_pagamento FROM pagamento WHERE pag_descricao = 'pix') ) THEN
			SET v_id_status_pedido = 1;
		ELSE
			SET v_id_status_pedido = 3;
		END IF;
		
		INSERT INTO pedido
		(id_estabelecimento, id_usuario, id_pagamento, id_status_pedido)
		VALUES
		(arg_id_estabelecimento, arg_id_usuario, arg_id_pagamento, v_id_status_pedido);

		SELECT 'pedido inserido com sucesso.' AS resultado;

		SELECT *
		FROM pedido
		ORDER BY id_pedido DESC;
	/* END IF; */
END$$
DELIMITER ;

/* cancelar pedido */ 
/* REVISADO ATÉ AQUI 2023-06-14 */

/* Avançar status de um pedido */

DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `avancarStatusDeUmPedido`(
	IN arg_id_pedido				INT,
    IN arg_id_status_pedido			INT
)
BEGIN
	DECLARE v_id_status_pedido INT;

	SET v_id_status_pedido = 0;

	SELECT id_status_pedido
	INTO v_id_status_pedido
	FROM pedido
	WHERE id_pedido = arg_id_pedido;

	IF (v_id_status_pedido = 0) THEN
		SELECT 'pedido não encontrado.' AS resultado;
	ELSE
		IF (v_id_status_pedido = (SELECT id_status_pedido FROM pedido WHERE stat_ped_descricao = 'cancelado')) THEN
			SELECT 'o pedido foi cancelado. não é possível alterar seu status.' AS resultado;
		ELSE
			UPDATE pedido
			SET id_status_pedido = id_status_pedido + 1
			WHERE id_pedido = arg_id_pedido;

			SELECT 'status alterado com sucesso.' AS resultado;

			SELECT *
			FROM pedido
			WHERE id_pedido BETWEEN (id_pedido - 2) AND (id_pedido + 2);
		END IF;
	END IF;

END$$
DELIMITER ;

/* avaliar pedido */

DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `avaliarPedido`(
	IN arg_id_estabelecimento	INT,
	IN arg_id_pedido			INT,
	IN arg_id_avaliacao			INT
)
BEGIN
	DECLARE v_id_pedido				INT;
	DECLARE v_id_status_pedido		INT;

	SET v_id_pedido = 0;
	SET v_id_status_pedido = 0;
	
	SELECT id_pedido, id_status_pedido
	INTO v_id_pedido, v_id_status_pedido
	FROM pedido
	WHERE id_pedido = arg_id_pedido
	AND id_estabelecimento = arg_id_estabelecimento;

	IF (v_id_pedido = 0) THEN
		SELECT 'pedido não encontrado.' AS resultado;
	ELSE
		IF (v_id_status_pedido BETWEEN 1 AND 5) THEN
			SELECT 'o status atual do pedido não permite avaliação.' AS resultado;
		ELSE
			UPDATE pedido
			SET id_avaliacao = arg_id_avaliacao
			WHERE id_pedido = arg_id_pedido;

			SELECT 'Pedido avaliado com sucesso.' AS resultado;

			CALL selecionarUmPedido(arg_id_pedido);
			/* SELECT *
			FROM pedido
			WHERE id_pedido = arg_id_pedido; */
		END IF;
	END IF;
END$$
DELIMITER ;

/* Selecionar um pedido */

DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `selecionarUmPedido`(IN arg_id_pedido INT)
BEGIN
	SELECT *
	FROM pedido
	WHERE id_pedido = arg_id_pedido;
END$$
DELIMITER ;


/* ITEM */

CREATE TABLE item (
	id_item 		INT PRIMARY KEY AUTO_INCREMENT,
    id_pedido		INT NOT NULL,
    id_produto		INT NOT NULL,
	it_quantidade	INT NOT NULL DEFAULT 1
);

ALTER TABLE item
ADD CONSTRAINT fk_id_pedido
FOREIGN KEY (id_pedido)
REFERENCES pedido(id_pedido);

ALTER TABLE item
ADD CONSTRAINT fk_id_produto
FOREIGN KEY (id_produto)
REFERENCES produto(id_produto);

/* validar se produtos existem nos estabelecimentos */
INSERT INTO item
(id_pedido, id_produto, it_quantidade)
VALUES
(1, 2, 1),
(1, 4, 1),
(2, 1, 2),
(2, 5, 1),
(3, 2, 2);

/* Pesquisar pessoa por e-mail */

DELIMITER $$
CREATE DEFINER=`root`@`localhost` FUNCTION `pesquisarPessoaPorEmail`(arg_pess_email VARCHAR(50)) RETURNS INT
BEGIN
	IF (arg_pess_email = '') THEN
		/* SELECT 'o nome da pessoa não foi informado.'; */
		RETURN 0;
	ELSE
		RETURN (
			SELECT id_pessoa
			FROM pessoa
			WHERE pess_email = arg_pess_email
		);
	END IF;
END$$
DELIMITER ;


/* ADICIONAL */

CREATE TABLE adicional (
	id_adicional	INT PRIMARY KEY AUTO_INCREMENT,
	adi_nome		VARCHAR(200) NOT NULL,
	adi_valor		DECIMAL(8, 2) NOT NULL,
	id_categoria	INT NOT NULL,
		CONSTRAINT fk_id_categoria_2
        FOREIGN KEY (id_categoria)
        REFERENCES categoria(id_categoria)
);


DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `inserirAdicional`(
	IN arg_adi_nome 		VARCHAR(200),
    IN arg_adi_valor 		decimal(8, 2),
    IN arg_id_categoria 	INT
)
BEGIN
	INSERT INTO adicional
    (adi_nome, adi_valor, id_categoria)
    VALUES
    (arg_adi_nome, arg_adi_valor, arg_id_categoria);
    
    SELECT *
    FROM adicional
    ORDER BY id_adicional DESC;
END$$
DELIMITER ;

INSERT INTO adicional
(adi_nome, adi_valor, id_categoria)
VALUES
('ovo', 2.99, 1),
('bacon', 3.99, 1),
('calda de menta', 2.99, 3),
('creme de avelã', 4.99, 3),
('limão', 1.99, 2);


/* ADICIONAL_ESTABELECIMENTO */

CREATE TABLE adicional_estabelecimento (
	id_adicional_estabelecimento	INT PRIMARY KEY AUTO_INCREMENT,
    id_adicional					INT NOT NULL,
		CONSTRAINT fk_id_adicional
        FOREIGN KEY (id_adicional)
        REFERENCES adicional(id_adicional),
	id_estabelecimento				INT NOT NULL,
		CONSTRAINT fk_id_estabelecimento_3
        FOREIGN KEY (id_estabelecimento)
        REFERENCES estabelecimento(id_estabelecimento),
	adi_est_valor					DECIMAL(8, 2) NOT NULL,
	adi_est_ativo					TINYINT(1) NOT NULL DEFAULT 1
);
	
/* evita duplicação de adicionais no mesmo estabelecimento */
ALTER TABLE adicional_estabelecimento
ADD UNIQUE unique_adicional_estabelecimento(id_adicional, id_estabelecimento);


DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `inserirAdicionalEstabelecimento`(
	IN arg_id_adicional			INT,
	IN arg_id_estabelecimento 	INT,
	IN arg_adi_est_valor	 	INT
)
BEGIN
	INSERT INTO adicional_estabelecimento
    (id_adicional, id_estabelecimento, adi_est_valor)
    VALUES
    (arg_id_adicional, arg_id_estabelecimento, arg_adi_est_valor);
    
    SELECT *
    FROM adicional_estabelecimento
    ORDER BY id_adicional_estabelecimento DESC;
END$$
DELIMITER ;

INSERT INTO adicional_estabelecimento
(id_adicional, id_estabelecimento, adi_est_valor)
VALUES
(5, 2, 1.99),
(1, 2, 1.99),
(2, 1, 2.99),
(1, 1, 2.99),
(3, 1, 2.99);


/* ADICIONAL_ITEM */

CREATE TABLE adicional_item (
	id_adicional_item	INT PRIMARY KEY AUTO_INCREMENT,
	id_adicional		INT NOT NULL,
		CONSTRAINT fk_id_adicional_2
        FOREIGN KEY (id_adicional)
        REFERENCES adicional(id_adicional),
	id_item				INT NOT NULL,
		CONSTRAINT fk_id_item
        FOREIGN KEY (id_item)
        REFERENCES item(id_item),
	adi_it_quantidade	INT NOT NULL DEFAULT 1
);

INSERT INTO adicional_item
(id_adicional, id_item, adi_it_quantidade)
VALUES
(5, 2, 1),
(1, 1, 2),
(2, 1, 1),
(3, 4, 2),
(5, 2, 2);


/* CANCELAMENTO */

CREATE TABLE cancelamento (
	id_cancelamento	INT PRIMARY KEY AUTO_INCREMENT,
    id_pedido		INT UNIQUE NOT NULL,
    canc_motivo			VARCHAR(1000)
);
    
ALTER TABLE cancelamento 
ADD CONSTRAINT fk_id_pedido_2
FOREIGN KEY (id_pedido)
REFERENCES pedido(id_pedido);    
    

/* RECEITA DE VENDAS */

CREATE TABLE receita_venda (
	id_receita_venda	INT PRIMARY KEY AUTO_INCREMENT,
	id_pedido			INT UNIQUE NOT NULL,
		CONSTRAINT fk_id_pedido_3
		FOREIGN KEY (id_pedido)
		REFERENCES pedido(id_pedido),
	rec_valor				DECIMAL(8, 2) NOT NULL,
		CONSTRAINT check_valor_positivo_2
		CHECK (rec_valor > 0),
	rec_data_hora			DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP()
);


/* PIX */

/* CREATE TABLE pix (
	id_pix		INT PRIMARY KEY AUTO_INCREMENT,
	id_pedido	INT NOT NULL,
		CONSTRAINT fk_id_pedido_4
		FOREIGN KEY (id_pedido)
		REFERENCES pedido(id_pedido),
	pix_codigo	CHAR(26) NOT NULL
); */


/* OUTROS PROCEDURES */

DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `listarAdicionaisDeEstabelecimentos`()
BEGIN
	SELECT est_nome, adi_nome, valor
	FROM estabelecimento
	JOIN adicional_estabelecimento
	ON estabelecimento.id_estabelecimento = adicional_estabelecimento.id_estabelecimento
    
    JOIN adicional
    ON adicional_estabelecimento.id_adicional = adicional.id_adicional
    
    ORDER BY est_nome, id_categoria, adi_nome;
END$$
DELIMITER ;

DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `listarItensDoPedido`(IN arg_id_pedido INT)
BEGIN
	SELECT pedido.id_pedido, item.id_item, produto.nome, nome
    FROM pedido
    JOIN item
    ON item.id_pedido = pedido.id_pedido
    
    JOIN produto
    ON item.id_produto = produto.id_produto
    
    JOIN categoria
    ON produto.id_categoria = categoria.id_categoria
    
    JOIN adicional_item
    ON adicional_item.id_item = item.id_item
    
    JOIN adicional
    ON adicional.id_adicional = adicional_item.id_adicional
    
    WHERE pedido.id_pedido = arg_id_pedido
    ORDER BY id_pedido, id_item, categoria.id_categoria;
END$$
DELIMITER ;

DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `inserirAdicionalItem`(
	IN arg_id_estabelecimento	INT,
	IN arg_id_adicional			INT,
	IN arg_id_item				INT
)
BEGIN
	DECLARE v_id_adicional_estabelecimento		INT;
    DECLARE v_id_categoria_produto_principal	INT;
    DECLARE v_id_categoria_adicional			INT;
    DECLARE v_id_estabelecimento				INT;
    
    SET v_id_adicional_estabelecimento = 0;
    /* categorias compatíveis */
    SET v_id_categoria_produto_principal = 0;
    SET v_id_categoria_adicional = 0;
    /* item e estabelecimento compatíveis */
    SET v_id_estabelecimento = 0;
    
    /* verifica se o item informado pertence a um pedido do estabelecimento informado. */
    SELECT id_estabelecimento
    INTO v_id_estabelecimento
    FROM item
    JOIN pedido
    ON item.id_pedido = pedido.id_pedido
    WHERE item.id_item = arg_id_item;
    
    IF ( v_id_estabelecimento = 0 ) THEN
		SELECT 'o item informado não pertence a um pedido do estabelecimento informado.';
	ELSE
		-- verifica se o estabelecimento possui o adicional solicitado pelo cliente.
		SELECT id_adicional_estabelecimento
		INTO v_id_adicional_estabelecimento
		FROM adicional_estabelecimento
		WHERE id_adicional = arg_id_adicional
		AND id_estabelecimento = arg_id_estabelecimento;
		
		IF ( v_id_adicional_estabelecimento = 0 ) THEN
			SELECT 'adicional indisponível no estabelecimento informado.';
		ELSE
			-- verifica se a categoria do adicional é a mesma do produto principal.
			-- essa checagem impede a adição de 'calda de menta' em um 'x-bacon', por exemplo.
			SELECT id_categoria
			INTO v_id_categoria_produto_principal
			FROM item
			JOIN produto
			ON item.id_produto = produto.id_produto
			WHERE id_item = arg_id_item;
			
			SELECT id_categoria
			INTO v_id_categoria_adicional
			FROM adicional
			WHERE id_adicional = arg_id_adicional;

			IF ( v_id_categoria_produto_principal <> v_id_categoria_adicional ) THEN
				SELECT 'as categorias do adicional e do produto principal são incompatíveis.';
			ELSE
				INSERT INTO adicional_item
				(id_adicional, id_item)
				VALUES
				(arg_id_adicional, arg_id_item);
				
				SELECT 'adicional registrado com sucesso.';
				
				SELECT *
				FROM adicional_item
				ORDER BY id_adicional DESC;
			END IF;
		END IF;
    END IF;
	
END$$
DELIMITER ;

DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `inserirProdutoNoPedido`(
	IN arg_id_estabelecimento	INT,
	IN arg_id_pedido			INT,
    IN arg_id_produto			INT
)
BEGIN

	DECLARE v_id_estabelecimento INT;
	DECLARE v_id_pedido INT;
	DECLARE v_id_produto INT;
    
    SET v_id_estabelecimento = 0;
    SET v_id_pedido = 0;
    SET v_id_produto = 0;
    
    /* verifica se o pedido pertence ao estabelecimento informado. */
    SELECT id_pedido
	INTO v_id_pedido
	FROM pedido
	JOIN estabelecimento
	ON pedido.id_estabelecimento = estabelecimento.id_estabelecimento
    
	WHERE pedido.id_pedido = arg_id_pedido
    AND estabelecimento.id_estabelecimento = arg_id_estabelecimento;
    
    IF (v_id_pedido = 0) THEN
		SELECT 'o pedido informado não pertence ao estabelecimento informado.';
	ELSE
		/* verifica se o estabelecimento informado possui o produto informado. */
        SELECT id_produto
        INTO v_id_produto
		FROM produto
		WHERE id_produto = arg_id_produto
		AND id_estabelecimento = arg_id_estabelecimento;
        
        IF (v_id_produto = 0) THEN
			SELECT 'o estabelecimento não possui o produto informado.';
		ELSE
			INSERT INTO item
            (id_pedido, id_produto)
            VALUES
            (arg_id_pedido, arg_id_produto);
            
            SELECT 'produto adicionado com sucesso.';
        
        END IF;
	END IF;
    
END$$
DELIMITER ;

CREATE DEFINER=`root`@`localhost` PROCEDURE `listarAdicionaisDoPedido`(IN arg_id_pedido INT)
BEGIN
	SELECT pedido.id_pedido, adicional.id_adicional, nome, valor
    FROM pedido
    JOIN item
    ON pedido.id_pedido = item.id_pedido
    
    JOIN adicional_item
    ON adicional_item.id_item = item.id_item
    
    JOIN adicional
    ON adicional_item.id_adicional = adicional.id_adicional
	WHERE pedido.id_pedido = arg_id_pedido

END$$
DELIMITER ;



DELIMITER $$
CREATE DEFINER=`root`@`localhost` FUNCTION `somarAdicionaisDoPedido`(arg_id_pedido INT) RETURNS decimal(8, 2)
BEGIN
	RETURN (
		SELECT SUM(valor)
		FROM pedido
		JOIN item
		ON pedido.id_pedido = item.id_pedido
		
		JOIN adicional_item
		ON adicional_item.id_item = item.id_item
		
		JOIN adicional
		ON adicional_item.id_adicional = adicional.id_adicional
		
		WHERE pedido.id_pedido = arg_id_pedido
	);

END$$
DELIMITER ;

DELIMITER $$
CREATE DEFINER=`root`@`localhost` FUNCTION `somarItensDoPedido`(arg_id_pedido INT) RETURNS decimal(8, 2)
BEGIN
	RETURN (
		SELECT SUM(valor)
		FROM pedido
		JOIN item
		ON item.id_pedido = pedido.id_pedido

		JOIN produto
		ON item.id_produto = produto.id_produto

		WHERE pedido.id_pedido = arg_id_pedido
	);
END$$
DELIMITER ;

DELIMITER $$
CREATE DEFINER=`root`@`localhost` FUNCTION `somarPedido`(arg_id_pedido INT) RETURNS decimal(8, 2)
BEGIN
	SET @soma_itens = somarItensDoPedido(arg_id_pedido);
	SET @soma_adicionais = somarAdicionaisDoPedido(arg_id_pedido);
    RETURN @soma_itens + @soma_adicionais;
END$$
DELIMITER ;

