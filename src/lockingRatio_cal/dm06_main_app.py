"""This is the main application to run the GUI and dm06_LT module"""

import time
import sys
from DM06_LT_Pkg.dm06_LT import *
from GUI_apps.dm06_GUI.dm06_LT_app import *
from PyQt5.QtWidgets import QApplication, QFileDialog, QMessageBox


class DM06MainWindow(Ui_MainWindow):
    """
    DM06 main window application.
    """
    # Define attribute
    dm06_ins = None
    __data_folder = ''  # Main data folder

    def __init__(self):
        super().__init__()

    def setupUi(self, MW):
        """
        Setup the UI of the super class. And add here code that relates to the way we want our UI to operate.
        :param MW: Input window object.
        :return:
        """
        super().setupUi(MW)
        self.Browse.clicked.connect(self.clk_browse)
        self.GenExcel.clicked.connect(self.clk_gen_excel)
        self.GenPlots.clicked.connect(self.clk_plt)
        self.SaveFigs.clicked.connect(self.sv_figures)
        self.Exit.clicked.connect(self.clk_exit)

    def clk_browse(self):
        """
        When click browse, open windows Explorer to select folder.
        And save folder direction.
        :return:
        """
        dir_name = QFileDialog.getExistingDirectory(self.Browse, 'Select data folder', 'C:\\')
        self.FolderLine.setText(dir_name)
        self.process_data()  # Start to process the data.
        pass

    def process_data(self):
        """
        Start to process the data. Read, splice, save data.
        :return:
        """
        self.__data_folder = self.FolderLine.text()
        dm06_ins = DM06LtDataPro(self.__data_folder)

        self.progressBar.setMinimum(0)
        self.progressBar.setMaximum(90)
        self.progressBar.setFormat('Read data.')
        time.sleep(.5)
        dm06_ins.read_data()

        self.progressBar.setValue(30)
        self.progressBar.setFormat('Splice data.')
        time.sleep(.5)
        dm06_ins.splice_data()

        self.progressBar.setValue(60)
        self.progressBar.setFormat('Average calculation.')
        time.sleep(.5)
        dm06_ins.avg_hr_data()

        self.progressBar.setValue(90)
        self.progressBar.setFormat('Completed!')

        self.dm06_ins = dm06_ins
        pass

    def clk_gen_excel(self):
        """
        When click generate excel, generate and save excel.
        :return:
        """
        self.dm06_ins.gen_excel()
        # Show message box 'Excel files saved!'
        QMessageBox.about(self.centralwidget, 'GenExcel', 'Excel files saved!')
        pass

    def clk_plt(self):
        """
        When click generate plots, generate the plotting.
        :return:
        """
        self.dm06_ins.gen_plts()
        pass

    @staticmethod
    def clk_exit():
        """
        When click exit, exit the application. Close all the open figures.
        :return:
        """
        sys.exit()
        pass

    def sv_figures(self):
        """
        When click, save and close all the open figures.
        :return:
        """
        self.dm06_ins.sv_figs()
        plt.close('all')
        QMessageBox.about(self.centralwidget, 'SvFigs', 'Open figures saved!')
        pass


def main():
    """
    This is the MAIN ENTRY POINT of our application.  The code at the end
    of the mainwindow.py script will not be executed, since this script is now
    our main program.   We have simply copied the code from mainwindow.py here
    since it was automatically generated by '''pyuic5'''.
    """
    app = QApplication(sys.argv)
    MainWindow = QtWidgets.QMainWindow()
    ui = DM06MainWindow()
    ui.setupUi(MainWindow)
    MainWindow.show()
    sys.exit(app.exec_())


# Launch the main application.
if __name__ == '__main__':
    main()
