import 'dart:async';

import 'package:meta/meta.dart';

import '../models/base/transaction.dart';
import '../models/card.dart';
import '../models/deck.dart';
import '../models/scheduled_card.dart';

class CardViewModel {
  CardModel card;
  DeckModel deck;

  CardViewModel({@required this.deck, this.card}) : assert(deck != null) {
    card ??= CardModel();
  }

  CardViewModel._copyFrom(CardViewModel other)
      : card = CardModel.copyFrom(other.card),
        deck = DeckModel.copyFrom(other.deck);
}

class CardPreviewBloc {
  CardPreviewBloc({@required CardModel card, @required DeckModel deck})
      : assert(card != null),
        assert(deck != null),
        deckNameValue = deck.name {
    _cardValue = CardViewModel(card: card, deck: deck);
    _deleteCardController.stream.listen(_deleteCard);
  }

  final String deckNameValue;
  // TODO(dotdoom): add deckNameStream.

  CardViewModel _cardValue;
  CardViewModel get cardValue => CardViewModel._copyFrom(_cardValue);

  Stream<CardViewModel> get cardStream =>
      // TODO(dotdoom): mux in DeckModel updates stream, too.
      CardModel.get(deckKey: _cardValue.card.deckKey, key: _cardValue.card.key)
          .transform(StreamTransformer.fromHandlers(
              handleData: (cardModel, sink) async {
        if (cardModel.key == null) {
          // Card doesn't exist anymore. Do not send any events
          sink.close();
        } else {
          sink.add(cardValue);
        }
      }));

  // TODO(ksheremet): Figure out whether to call close() on dispose
  // ignore: close_sinks
  final _deleteCardController = StreamController<String>();
  Sink<String> get deleteCard => _deleteCardController.sink;

  void _deleteCard(String uid) {
    // TODO(dotdoom): move to models?
    (Transaction()
          ..delete(_cardValue.card)
          ..delete(ScheduledCardModel(card: _cardValue.card, uid: uid)))
        .commit();
  }
}
