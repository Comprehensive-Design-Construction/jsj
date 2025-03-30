import fitz  # PyMuPDF
import tkinter as tk
from tkinter import filedialog
from PIL import Image, ImageTk

class PDFViewer:
    def __init__(self, root):
        self.root = root
        self.root.title("PDF Viewer")
        self.canvas = tk.Canvas(root)
        self.canvas.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)

        self.scroll_y = tk.Scrollbar(root, orient="vertical", command=self.canvas.yview)
        self.scroll_y.pack(side=tk.RIGHT, fill=tk.Y)

        self.canvas.configure(yscrollcommand=self.scroll_y.set)

        self.canvas.bind('<Configure>', lambda e: self.canvas.configure(scrollregion=self.canvas.bbox("all")))

        self.frame = tk.Frame(self.canvas)
        self.canvas.create_window((0,0), window=self.frame, anchor="nw")

    def open_pdf(self, path = ("C:\\Users\\USER\Desktop\\종설제\\240610_국민행동요령_폭염_v2.pdf")):
        document = fitz.open(path)
        for page_number in range(document.page_count):
            page = document.load_page(page_number)
            pix = page.get_pixmap()
            img = Image.frombytes("RGB", [pix.width, pix.height], pix.samples)

            photo = ImageTk.PhotoImage(img)
            label = tk.Label(self.frame, image=photo)
            label.image = photo  # Keep a reference
            label.pack()

if __name__ == "__main__":
    root = tk.Tk()
    viewer = PDFViewer(root)

    # PDF 파일 열기
    pdf_file_path = filedialog.askopenfilename(filetypes=[("PDF Files", "*.pdf")])
    if pdf_file_path:
        viewer.open_pdf("C:\\Users\\USER\Desktop\\종설제\\240610_국민행동요령_폭염_v2.pdf")  # 선택한 파일 경로를 전달

    root.mainloop()