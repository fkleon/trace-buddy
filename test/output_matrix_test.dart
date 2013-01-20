part of rt_test_suite;

/**
 *  Contains methods to test the output matrix implementation.
 */
class OutputMatrixTests extends TestSet {

  get name => 'Output Matrix Tests';

  get testFunctions => {
    'Matrix Creation': matrixCreation,
    'Matrix Manipulation': matrixManipulation,
    'Matrix Clear': matrixClear
  };

  // Initialises the matrix and color vectors.
  void initTests() {
    om = new OutputMatrix(rows, columns);
    black = new vec3.zero();
    white = new vec3.raw(1,1,1);
    red = new vec3(1,0,0);
  }

  /*
   *  Tests and variables.
   */
  final int rows = 100, columns = 99;
  OutputMatrix om;
  vec3 black, white, red;

  // Tests the expected state of the matrix after creation.
  matrixCreation() {
    // expect some errors on invalid access
    expect(() => om.getPixel(0, 0), throwsArgumentError);
    expect(() => om.getPixel(-1, -200), throwsArgumentError);
    expect(() => om.getPixel(1, columns+1), throwsArgumentError);
    expect(() => om.getPixel(rows+1, columns), throwsRangeError);
    expect(() => om.getRow(-1), throwsRangeError);

    // expect normal returns on valid access
    expect(() => om.getRow(1), returnsNormally);
    expect(() => om.getRow(rows), returnsNormally);

    // expect all pixels to be black
    expect(isBlack(om.getPixel(1, 1)), isTrue);
    expect(isBlack(om.getPixel(rows, columns)), isTrue);

    for (int i = 1; i<=rows; i++) {
      for (int j = 1; j<=columns; j++)
        expect(isBlack(om.getPixel(i, j)), isTrue);
    }

    // expect all rows to return normally
    for (int i = 1; i<=rows; i++) {
      expect(() => om.getRow(i),returnsNormally);
    }
  }

  bool isBlack(vec3 color) {
    return color.x == 0 && color.y == 0 && color.z == 0;
  }

  bool isWhite(vec3 color) {
    return color.x == 1 && color.y == 1 && color.z == 1;
  }

  bool isRed(vec3 color) {
    return color.x == 1 && color.y == 0 && color.z == 0;
  }

  // Tests the expected state of the matrix after pixel and row manipulations.
  matrixManipulation() {
    // expect a red pixel
    om.setPixel(2, 5, red);
    expect(isRed(om.getPixel(2,5)),isTrue);

    // build red row
    List<vec3> redRow = new List<vec3>(columns);
    for (int i=0; i<columns; i++) {
      redRow[i] = red;
    }

    // expect a red row
    om.setRow(5, redRow);
    for (var color in om.getRow(5)) {
      expect(isRed(color),isTrue);
    }

    // but everything else should be black
    for (int r=6; r<rows; r++) {
      for (var color in om.getRow(r)) {
        expect(isBlack(color),isTrue);
      }
    }
  }

  // Tests the expected state of the matrix after the clear operation.
  matrixClear() {
    om.clear();

    // expect all pixels to be black after clear
    for (int i = 1; i<=rows; i++) {
      for (int j = 1; j<=columns; j++)
        expect(isBlack(om.getPixel(i, j)), isTrue);
    }
  }
}