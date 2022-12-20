contract RockPaperScissorsGame {
    enum PlayerChoise {
        NULL,
        ROCK,
        PAPER,
        SCISSORS
    }

    enum GameStatus {
        NULL,
        CREATED,
        COMMIT_PHASE,
        REVEAL_PHASE,
        DONE
    }

    struct Player {
        address payable playerAddress;
        PlayerChoise choice;
        uint256 nonce;
        bytes32 hashedShape;
    }

    struct Game {
        Player firstPlayer;
        Player secondPlayer;
        GameStatus status;
        uint256 bet;
    }

    uint256 gameId;
    address owner;
    mapping(uint256 => Game) public allGames;

    constructor() {
        owner = msg.sender;
    }

    function createGame(address payable secondPlayer)
        external
        payable
        returns (uint256)
    {
        require(msg.value > 0, "Bet must be > 0");

        Game memory game;
        game.firstPlayer.playerAddress = payable(msg.sender);
        game.secondPlayer.playerAddress = payable(secondPlayer);
        game.bet = msg.value;
        game.status = GameStatus.CREATED;

        allGames[gameId] = game;
        return gameId++;
    }

    function playGame(
        uint256 id,
        PlayerChoise choice,
        uint256 nonce
    ) external payable gameInputCorrect(id, choice) {
        require(allGames[id].status == GameStatus.CREATED);
        require(msg.value >= allGames[id].bet, "Value is not enough");

        if (msg.sender == allGames[id].firstPlayer.playerAddress) {
            allGames[id].firstPlayer.hashedShape = keccak256(
                abi.encodePacked(choice, nonce)
            );
        } else if (msg.sender == allGames[id].secondPlayer.playerAddress) {
            allGames[id].secondPlayer.hashedShape = keccak256(
                abi.encodePacked(choice, nonce)
            );
        }

        if (msg.value > allGames[id].bet) {
            payable(msg.sender).transfer(msg.value - allGames[id].bet);
        }

        if (
            allGames[id].firstPlayer.hashedShape != 0 &&
            allGames[id].secondPlayer.hashedShape != 0
        ) {
            allGames[id].status = GameStatus.COMMIT_PHASE;
        }
    }

    function revealGame(
        uint256 id,
        PlayerChoise choice,
        uint256 nonce
    ) external gameInputCorrect(id, choice) {
        require(allGames[id].status == GameStatus.COMMIT_PHASE);

        bytes32 hashedShape = keccak256(abi.encodePacked(choice, nonce));

        if (
            (allGames[id].firstPlayer.playerAddress == msg.sender) &&
            (hashedShape == allGames[id].firstPlayer.hashedShape)
        ) {
            allGames[id].firstPlayer.choice = choice;
            allGames[id].firstPlayer.nonce = nonce;
        } else if (
            (allGames[id].secondPlayer.playerAddress == msg.sender) &&
            (hashedShape == allGames[id].secondPlayer.hashedShape)
        ) {
            allGames[id].secondPlayer.choice = choice;
            allGames[id].secondPlayer.nonce = nonce;
        }

        if (
            allGames[id].firstPlayer.choice != PlayerChoise.NULL &&
            allGames[id].secondPlayer.choice != PlayerChoise.NULL
        ) {
            allGames[id].status = GameStatus.REVEAL_PHASE;
        }
    }

    function chooseWinner(uint256 id) external returns (address) {
        require(allGames[id].status == GameStatus.REVEAL_PHASE);

        address payable first = allGames[id].firstPlayer.playerAddress;
        address payable second = allGames[id].secondPlayer.playerAddress;
        address payable winner;

        if (
            allGames[id].firstPlayer.choice == allGames[id].secondPlayer.choice
        ) {
            allGames[id].firstPlayer.playerAddress.transfer(allGames[id].bet);
            allGames[id].secondPlayer.playerAddress.transfer(allGames[id].bet);
            return winner;
        } else if (allGames[id].firstPlayer.choice == PlayerChoise.PAPER) {
            winner = allGames[id].secondPlayer.choice == PlayerChoise.SCISSORS
                ? second
                : first;
        } else if (allGames[id].firstPlayer.choice == PlayerChoise.ROCK) {
            winner = allGames[id].secondPlayer.choice == PlayerChoise.PAPER
                ? second
                : first;
        } else if (allGames[id].firstPlayer.choice == PlayerChoise.SCISSORS) {
            winner = allGames[id].secondPlayer.choice == PlayerChoise.ROCK
                ? second
                : first;
        }

        winner.transfer(allGames[id].bet * 2);
        allGames[id].status = GameStatus.DONE;
        return winner;
    }

    modifier gameInputCorrect(uint256 id, PlayerChoise shape) {
        require(allGames[id].status != GameStatus.NULL);
        require(shape != PlayerChoise.NULL);
        require(
            msg.sender == allGames[id].firstPlayer.playerAddress ||
                msg.sender == allGames[id].secondPlayer.playerAddress
        );
        _;
    }
}
