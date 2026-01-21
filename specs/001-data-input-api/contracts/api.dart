/// Abstract API Contract for Braven Data

abstract class Series<TX, TY> {
  String get id;
  SeriesMeta get meta;
  int get length;

  TX getX(int index);
  TY getY(int index);

  /// Returns a subset of the series
  Series<TX, TY> slice(int start, [int? end]);

  /// Applies a pipeline of transformations
  Series<TX, TY> transform(Pipeline<TX, TY> pipeline);

  /// Aggregates the series based on specifications
  Series<TX, TY> aggregate(AggregationSpec<TX> spec);
}

abstract class SeriesStorage<TX, TY> {
  int get length;
  TX getAtIndexX(int index);
  TY getAtIndexY(int index);
}

abstract class Reducer<T> {
  T reduce(List<T> values);
}

abstract class Pipeline<TX, TY> {
  Pipeline map(Mapper<TY> mapper);
  Pipeline rolling(WindowSpec window, Reducer reducer);
  Series<TX, TY> execute(Series<TX, TY> input);
}

class WindowSpec {
  // Factory constructors for Fixed, Rolling, PixelAligned
}
