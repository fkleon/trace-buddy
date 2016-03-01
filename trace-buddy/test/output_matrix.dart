part of tracebuddy_test_suite;

/**
 *  Contains methods to test the output matrix implementation.
 */
class OutputMatrixTests extends TestSet {

  get name => 'Output Matrix Tests';

  get testFunctions => {
    'Matrix Creation': matrixCreation,
    'Matrix Manipulation (pixel)': matrixManipulationPixel,
    'Matrix Manipulation (row)': matrixManipulationRow,
    'Matrix Clear': matrixClear
  };

  // Initialises the matrix and color vectors.
  void initTests() {
    om = new OutputMatrix(rows, columns);
    black = new Vector4.zero();
    white = new Vector4(1.0,1.0,1.0,1.0);
    red = new Vector4(1.0,0.0,0.0,1.0);
  }

  /*
   *  Tests and variables.
   */
  final int rows = 100, columns = 99;
  OutputMatrix om;
  Vector4 black, white, red;

  // Tests the expected state of the matrix after creation.
  matrixCreation() {
    // expect some errors on invalid access
    expect(() => om.getPixel(-1, -1), throwsArgumentError);
    expect(() => om.getPixel(rows, columns), throwsArgumentError);
    expect(() => om.getPixel(-1, -200), throwsArgumentError);
    expect(() => om.getPixel(1, columns+1), throwsArgumentError);
    expect(() => om.getPixel(rows+1, columns), throwsArgumentError);
    expect(() => om.getRow(-1), throwsArgumentError);

    // expect normal returns on valid access
    expect(() => om.getRow(1), returnsNormally);
    expect(() => om.getRow(rows-1), returnsNormally);

    // expect all pixels to be black
    expect(isBlack(om.getPixel(0, 0)), isTrue);
    expect(isBlack(om.getPixel(rows-1, columns-1)), isTrue);

    for (int i = 0; i<rows; i++) {
      for (int j = 0; j<columns; j++) {
        expect(isBlack(om.getPixel(i, j)), isTrue);
      }
    }

    // expect all rows to return normally
    for (int i = 0; i<rows; i++) {
      expect(() => om.getRow(i),returnsNormally);
    }
  }

  bool isBlack(Vector4 color) => color == black.scaled(255.0);
  bool isWhite(Vector4 color) => color == white.scaled(255.0);
  bool isRed(Vector4 color)   => color == red.scaled(255.0);

  // Tests the expected state of the matrix after pixel..
  matrixManipulationPixel() {
    // expect a red pixel
    om.setPixel(2, 5, red);
    expect(isRed(om.getPixel(2,5)),isTrue);
  }

  //  ..and row manipulations.
  matrixManipulationRow() {
    // build red row
    List<Vector4> redRow = new List<Vector4>(columns);
    for (int i = 0; i < columns; i++) {
      redRow[i] = red;
    }

    // expect a red row
    om.setRow(5, redRow);
    for (var color in om.getRow(5)) {
      expect(isRed(color),isTrue);
    }

    // but everything else should be black
    for (int r = 6; r < rows; r++) {
      for (var color in om.getRow(r)) {
        expect(isBlack(color),isTrue);
      }
    }
  }

  // Tests the expected state of the matrix after the clear operation.
  matrixClear() {
    om.clear();

    // expect all pixels to be black after clear
    for (int i = 0; i<rows; i++) {
      for (int j = 0; j<columns; j++) {
        expect(isBlack(om.getPixel(i, j)), isTrue);
      }
    }
  }
}
